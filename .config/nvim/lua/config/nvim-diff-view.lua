local M = {}

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

--- Show file at a specific revision in a split (supports jj and git)
function M.file_show(opts)
  local ctx, err = current_file_ctx()
  if not ctx then
    vim.notify(err, vim.log.levels.ERROR, { title = "vcs file show" })
    return
  end

  local prompt = ctx.vcs == "jj" and "jj revision (commit/change id): " or "git revision (commit/ref): "

  vim.ui.input({ prompt = prompt }, function(rev)
    if not rev or rev == "" then
      return
    end

    local cmd
    if ctx.vcs == "jj" then
      cmd = vim.system({ "jj", "file", "show", "-r", rev, ctx.rel_path }, {
        cwd = ctx.repo_root,
        text = true,
      }):wait()
    else
      cmd = vim.system({ "git", "show", rev .. ":" .. ctx.rel_path }, {
        cwd = ctx.repo_root,
        text = true,
      }):wait()
    end

    if cmd.code ~= 0 then
      local err_msg = (cmd.stderr or cmd.stdout or "file show failed"):gsub("%s+$", "")
      vim.notify(err_msg, vim.log.levels.ERROR, { title = ctx.vcs .. " file show" })
      return
    end

    local output = vim.split(cmd.stdout or "", "\n", { plain = true })
    if output[#output] == "" then
      table.remove(output)
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

return M
