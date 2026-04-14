local M = {}

local function current_file_ctx()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return nil, "Current buffer has no file"
  end

  local abs_path = vim.fs.normalize(vim.fn.fnamemodify(file, ":p"))
  local file_dir = vim.fs.dirname(abs_path)
  local root_cmd = vim.system({ "jj", "root" }, { cwd = file_dir, text = true }):wait()

  if root_cmd.code ~= 0 then
    local err = (root_cmd.stderr or root_cmd.stdout or "Not inside a jj repo"):gsub("%s+$", "")
    return nil, err
  end

  local repo_root_raw = (root_cmd.stdout or ""):gsub("%s+$", "")
  local repo_root = vim.fs.normalize(repo_root_raw)
  local rel_path = vim.fs.relpath(repo_root, abs_path)
  if not rel_path then
    return nil, string.format("Path %q is not inside jj repo %q", abs_path, repo_root)
  end

  return {
    abs_path = abs_path,
    repo_root = repo_root,
    rel_path = rel_path,
    filetype = vim.bo.filetype,
  }
end

-- Show file at a specific jj revision in a split
function M.jj_file_show(opts)
  local ctx, err = current_file_ctx()
  if not ctx then
    vim.notify(err, vim.log.levels.ERROR, { title = "jj file show" })
    return
  end

  vim.ui.input({ prompt = "jj revision (commit/change id): " }, function(rev)
    if not rev or rev == "" then
      return
    end

    local cmd = vim.system({ "jj", "file", "show", "-r", rev, ctx.rel_path }, {
      cwd = ctx.repo_root,
      text = true,
    }):wait()

    if cmd.code ~= 0 then
      local err_msg = (cmd.stderr or cmd.stdout or "jj file show failed"):gsub("%s+$", "")
      vim.notify(err_msg, vim.log.levels.ERROR, { title = "jj file show" })
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
