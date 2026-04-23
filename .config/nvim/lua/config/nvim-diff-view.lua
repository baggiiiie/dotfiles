local M = {}

-- ── State ──────────────────────────────────────────────────────────────

---@class ReviewComment
---@field file string
---@field start_line number
---@field end_line number
---@field comment string

---@type ReviewComment[]
M._reviews = {}

---@class DiffSession
---@field vcs "jj"|"git"
---@field repo_root string
---@field rev string
---@field files string[]        -- list of relative paths
---@field current_idx number
---@field diff boolean
---@field rev_buf? number       -- left-side (revision) buffer
---@field work_buf? number      -- right-side (working tree) buffer

---@type DiffSession?
M._session = nil

-- ── VCS helpers ────────────────────────────────────────────────────────

---@return "jj"|"git"|nil, string?
local function detect_vcs(dir)
  local jj = vim.system({ "jj", "root" }, { cwd = dir, text = true }):wait()
  if jj.code == 0 then
    local root = vim.fs.normalize(((jj.stdout or ""):gsub("%s+$", "")))
    return "jj", root
  end

  local git = vim.system({ "git", "rev-parse", "--show-toplevel" }, { cwd = dir, text = true }):wait()
  if git.code == 0 then
    local root = vim.fs.normalize(((git.stdout or ""):gsub("%s+$", "")))
    return "git", root
  end

  return nil, nil
end

local function current_file_ctx()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return nil, "Current buffer has no file"
  end

  local abs_path = vim.fs.normalize(vim.fn.fnamemodify(file, ":p"))
  local file_dir = vim.fs.dirname(abs_path)
  local vcs, repo_root = detect_vcs(file_dir)

  if not vcs then
    return nil, "Not inside a jj or git repo"
  end

  local rel_path = vim.fs.relpath(repo_root, abs_path)
  if not rel_path then
    return nil, string.format("Path %q is not inside %s repo %q", abs_path, vcs, repo_root)
  end

  return {
    vcs = vcs,
    abs_path = abs_path,
    repo_root = repo_root,
    rel_path = rel_path,
    filetype = vim.bo.filetype,
  }
end

---@return string[]|nil, string?
local function changed_files(vcs, repo_root, rev)
  local args
  if vcs == "jj" then
    args = { "jj", "diff", "--summary", "--from", rev }
  else
    args = { "git", "diff", "--name-only", rev .. "..HEAD" }
  end

  vim.notify(table.concat(args, " "), vim.log.levels.INFO, { title = "diff review" })

  local cmd = vim.system(args, { cwd = repo_root, text = true }):wait()

  if cmd.code ~= 0 then
    return nil, (cmd.stderr or cmd.stdout or "failed to list changed files"):gsub("%s+$", "")
  end

  local files = {}
  for line in (cmd.stdout or ""):gmatch("[^\n]+") do
    if vcs == "jj" then
      -- jj diff --summary output: "M path/to/file"
      local path = line:match("^%S+%s+(.+)$")
      if path then
        table.insert(files, path)
      end
    else
      local trimmed = vim.trim(line)
      if trimmed ~= "" then
        table.insert(files, trimmed)
      end
    end
  end

  if #files == 0 then
    return nil, "No changed files in revision " .. rev
  end

  return files, nil
end

local function file_contents_at_rev(vcs, repo_root, rev, rel_path)
  local cmd
  if vcs == "jj" then
    cmd = vim.system({ "jj", "file", "show", "-r", rev, rel_path }, { cwd = repo_root, text = true }):wait()
  else
    cmd = vim.system({ "git", "show", rev .. ":" .. rel_path }, { cwd = repo_root, text = true }):wait()
  end

  if cmd.code ~= 0 then
    return nil, (cmd.stderr or cmd.stdout or "file show failed"):gsub("%s+$", "")
  end

  local output = vim.split(cmd.stdout or "", "\n", { plain = true })
  if output[#output] == "" then
    table.remove(output)
  end
  return output, nil
end

local function filetype_for(rel_path)
  local ft = vim.filetype.match({ filename = rel_path })
  return ft or ""
end

-- ── Single-file show (original) ────────────────────────────────────────

function M.file_show(opts)
  local ctx, err = current_file_ctx()
  if not ctx then
    vim.notify(err, vim.log.levels.ERROR, { title = "vcs file show" })
    return
  end

  local prompt = ctx.vcs == "jj" and "jj revision to diff against" or "git branch/tag/commit to diff against"

  vim.ui.input({ prompt = prompt }, function(rev)
    if not rev or rev == "" then
      return
    end

    local output, show_err = file_contents_at_rev(ctx.vcs, ctx.repo_root, rev, ctx.rel_path)
    if not output then
      vim.notify(show_err, vim.log.levels.ERROR, { title = ctx.vcs .. " file show" })
      return
    end

    vim.cmd("only")
    local orig_win = vim.api.nvim_get_current_win()
    vim.cmd("leftabove vsplit")
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = ctx.filetype
    vim.api.nvim_buf_set_name(buf, ctx.rel_path .. " @ " .. rev)
    if opts.diff then
      vim.cmd("diffthis")
      vim.api.nvim_set_current_win(orig_win)
      vim.cmd("diffthis")
    end
  end)
end

-- ── Multi-file diff review ─────────────────────────────────────────────

local function set_review_keymaps(bufnr)
  local opts = { buffer = bufnr, silent = true }
  vim.keymap.set("n", "]f", function()
    M.next_file()
  end, vim.tbl_extend("force", opts, { desc = "Next changed file" }))
  vim.keymap.set("n", "[f", function()
    M.prev_file()
  end, vim.tbl_extend("force", opts, { desc = "Previous changed file" }))
  vim.keymap.set("n", "<leader>rf", function()
    M.pick_file()
  end, vim.tbl_extend("force", opts, { desc = "Pick changed file" }))
  vim.keymap.set("x", "<leader>rc", function()
    M.add_comment()
  end, vim.tbl_extend("force", opts, { desc = "Add review comment" }))
  vim.keymap.set("n", "<leader>rs", function()
    M.open_scratchpad()
  end, vim.tbl_extend("force", opts, { desc = "Open review scratchpad" }))
  vim.keymap.set("n", "q", function()
    M.close_review()
  end, vim.tbl_extend("force", opts, { desc = "Close diff review" }))
end

local function open_file_at_index(idx)
  local s = M._session
  if not s then
    return
  end
  if idx < 1 or idx > #s.files then
    vim.notify("No more files", vim.log.levels.INFO, { title = "diff review" })
    return
  end

  s.current_idx = idx
  local rel_path = s.files[idx]
  local ft = filetype_for(rel_path)

  -- Get revision contents
  local rev_lines, err = file_contents_at_rev(s.vcs, s.repo_root, s.rev, rel_path)
  if not rev_lines then
    vim.notify(err, vim.log.levels.ERROR, { title = "diff review" })
    return
  end

  -- Clean up old diff state
  vim.cmd("diffoff!")

  -- Clean up old revision buffer
  if s.rev_buf and vim.api.nvim_buf_is_valid(s.rev_buf) then
    vim.api.nvim_buf_delete(s.rev_buf, { force = true })
  end

  vim.cmd("only")

  -- Left side: revision (scratch buffer — historical content)
  local rev_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(rev_buf, 0, -1, false, rev_lines)
  vim.bo[rev_buf].buftype = "nofile"
  vim.bo[rev_buf].modifiable = false
  vim.bo[rev_buf].filetype = ft
  pcall(vim.api.nvim_buf_set_name, rev_buf, rel_path .. " @ " .. s.rev)

  -- Right side: open the real file so LSP attaches
  local abs_path = s.repo_root .. "/" .. rel_path
  local work_buf = vim.fn.bufadd(abs_path)
  vim.fn.bufload(work_buf)

  s.rev_buf = rev_buf
  s.work_buf = work_buf

  -- Layout: left = revision, right = working tree (real file)
  vim.api.nvim_win_set_buf(0, rev_buf)
  vim.cmd("vertical rightbelow split")
  vim.api.nvim_win_set_buf(0, work_buf)

  if s.diff then
    vim.cmd("windo diffthis")
  end

  -- Set keymaps on both buffers
  set_review_keymaps(rev_buf)
  set_review_keymaps(work_buf)

  -- Statusline hint
  local title = string.format("[%d/%d] %s", idx, #s.files, rel_path)
  vim.notify(title, vim.log.levels.INFO, { title = "diff review" })
end

function M.diff_review(opts)
  opts = opts or {}
  local diff = opts.diff ~= false

  local cwd = vim.fn.getcwd()
  local vcs, repo_root = detect_vcs(cwd)
  if not vcs then
    vim.notify("Not inside a jj or git repo", vim.log.levels.ERROR, { title = "diff review" })
    return
  end

  local prompt = ctx.vcs == "jj" and "jj revision to diff against" or "git branch/tag/commit to diff against"

  vim.ui.input({ prompt = prompt }, function(rev)
    if not rev or rev == "" then
      return
    end

    local files, err = changed_files(vcs, repo_root, rev)
    if not files then
      vim.notify(err, vim.log.levels.ERROR, { title = "diff review" })
      return
    end

    M._session = {
      vcs = vcs,
      repo_root = repo_root,
      rev = rev,
      files = files,
      current_idx = 0,
      diff = diff,
    }

    -- Clear reviews for a fresh session
    M._reviews = {}

    open_file_at_index(1)
  end)
end

function M.next_file()
  local s = M._session
  if not s then
    vim.notify("No active diff review session", vim.log.levels.WARN, { title = "diff review" })
    return
  end
  open_file_at_index(s.current_idx + 1)
end

function M.prev_file()
  local s = M._session
  if not s then
    vim.notify("No active diff review session", vim.log.levels.WARN, { title = "diff review" })
    return
  end
  open_file_at_index(s.current_idx - 1)
end

function M.pick_file()
  local s = M._session
  if not s then
    vim.notify("No active diff review session", vim.log.levels.WARN, { title = "diff review" })
    return
  end

  vim.ui.select(s.files, {
    prompt = "Changed files:",
    format_item = function(item)
      local idx = 0
      for i, f in ipairs(s.files) do
        if f == item then
          idx = i
          break
        end
      end
      local marker = idx == s.current_idx and " ●" or ""
      return string.format("[%d] %s%s", idx, item, marker)
    end,
  }, function(_, idx)
    if idx then
      open_file_at_index(idx)
    end
  end)
end

function M.close_review()
  local s = M._session
  if not s then
    return
  end

  vim.cmd("diffoff!")

  if s.rev_buf and vim.api.nvim_buf_is_valid(s.rev_buf) then
    vim.api.nvim_buf_delete(s.rev_buf, { force = true })
  end

  M._session = nil
  vim.cmd("only")
end

-- ── Review comments / scratchpad ───────────────────────────────────────

function M.add_comment()
  local s = M._session
  -- Determine file context: use session if active, otherwise fall back to current buffer
  local rel_path
  if s then
    rel_path = s.files[s.current_idx]
  else
    local ctx, err = current_file_ctx()
    if not ctx then
      vim.notify(err, vim.log.levels.ERROR, { title = "review comment" })
      return
    end
    rel_path = ctx.rel_path
  end

  -- Get visual selection range from '< '> marks (works both during and after visual mode)
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  -- Exit visual mode if still in it
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  end

  -- Open a small floating input window
  local width = math.floor(vim.o.columns * 0.5)
  local height = 5
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local input_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[input_buf].buftype = "acwrite"
  vim.bo[input_buf].filetype = "markdown"
  pcall(vim.api.nvim_buf_set_name, input_buf, "nvdiff-review://" .. rel_path .. ":" .. (start_line or 0))

  local line_label
  if start_line == end_line then
    line_label = tostring(start_line)
  else
    line_label = start_line .. "-" .. end_line
  end

  local win = vim.api.nvim_open_win(input_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = string.format(" Review: %s:%s ", rel_path, line_label),
    title_pos = "center",
  })

  vim.cmd("startinsert")

  -- Save: <C-s> (insert or normal) to save, q/<Esc> to discard
  local function save_comment()
    local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
    local comment = vim.trim(table.concat(lines, "\n"))
    if comment == "" then
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_buf_delete(input_buf, { force = true })
      return
    end

    table.insert(M._reviews, {
      file = rel_path,
      start_line = start_line,
      end_line = end_line,
      comment = comment,
    })

    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(input_buf, { force = true })
    vim.notify(
      string.format("Comment saved for %s:%s", rel_path, line_label),
      vim.log.levels.INFO,
      { title = "review" }
    )
  end

  local function discard()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(input_buf, { force = true })
  end

  vim.keymap.set({ "n", "i" }, "<C-s>", save_comment, { buffer = input_buf, silent = true })
  vim.keymap.set("n", "<Esc>", discard, { buffer = input_buf, silent = true })

  -- Support :w / :wq to save the comment
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = input_buf,
    callback = function()
      save_comment()
    end,
  })
end

function M.open_scratchpad()
  if #M._reviews == 0 then
    vim.notify("No review comments yet", vim.log.levels.INFO, { title = "review scratchpad" })
    return
  end

  -- Build scratchpad content: numbered list
  local lines = { "This is my review:" }
  for i, r in ipairs(M._reviews) do
    local line_label
    if r.start_line == r.end_line then
      line_label = tostring(r.start_line)
    else
      line_label = r.start_line .. "-" .. r.end_line
    end
    -- Collapse multi-line comments into a single line with " | " separator
    local comment = r.comment:gsub("\n", " | ")
    table.insert(lines, string.format("%d. %s:%s: %s", i, r.file, line_label, comment))
  end

  local width = math.floor(vim.o.columns * 0.7)
  local height = math.floor(vim.o.lines * 0.7)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local pad_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(pad_buf, 0, -1, false, lines)
  vim.bo[pad_buf].filetype = "markdown"
  vim.bo[pad_buf].buftype = "nofile"

  local win = vim.api.nvim_open_win(pad_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Review Scratchpad ",
    title_pos = "center",
  })

  -- Parse edits back on close
  local function sync_and_close()
    local edited = vim.api.nvim_buf_get_lines(pad_buf, 0, -1, false)
    local new_reviews = {}

    for _, line in ipairs(edited) do
      -- Match: N. file:line_range: comment
      local file, line_range, comment = line:match("^%d+%. (.+):(%d+%-?%d*): (.+)$")
      if file and comment then
        local s, e = line_range:match("^(%d+)%-(%d+)$")
        if not s then
          s = line_range:match("^(%d+)$")
          e = s
        end
        -- Restore " | " back to newlines
        comment = comment:gsub(" | ", "\n")
        table.insert(new_reviews, {
          file = file,
          start_line = tonumber(s),
          end_line = tonumber(e),
          comment = comment,
        })
      end
    end

    M._reviews = new_reviews
    vim.api.nvim_win_close(win, true)
  end

  vim.keymap.set("n", "q", sync_and_close, { buffer = pad_buf, silent = true })
  vim.keymap.set("n", "<Esc>", sync_and_close, { buffer = pad_buf, silent = true })
end

-- ── User command ───────────────────────────────────────────────────────

vim.api.nvim_create_user_command("NvDiff", function(cmd_opts)
  local sub = vim.trim(cmd_opts.args)
  if sub == "files" then
    M.pick_file()
  elseif sub == "reviews" then
    M.open_scratchpad()
  elseif sub == "" then
    if cmd_opts.range > 0 then
      M.add_comment()
    else
      M.diff_review()
    end
  else
    vim.notify("Unknown subcommand: " .. sub, vim.log.levels.ERROR, { title = "NvDiff" })
  end
end, {
  nargs = "?",
  range = true,
  complete = function()
    return { "files", "reviews" }
  end,
  desc = "NvDiff: files | reviews | (visual) add comment",
})

return M
