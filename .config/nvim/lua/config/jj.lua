local M = {}

-- Show file at a specific jj revision in a split
function M.jj_file_show(opts)
  local ft = vim.bo.filetype
  vim.ui.input({ prompt = "jj revision (commit/change id): " }, function(rev)
    if not rev or rev == "" then
      return
    end
    local rel_path = vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.")
    local output = vim.fn.systemlist({ "jj", "file", "show", "-r", rev, rel_path })
    if vim.v.shell_error ~= 0 then
      vim.notify(table.concat(output, " "), vim.log.levels.ERROR, { title = "jj file show" })
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
    vim.bo[buf].filetype = ft
    vim.api.nvim_buf_set_name(buf, rel_path .. " @ " .. rev)
    if opts.diff then
      vim.cmd("diffthis")
      vim.api.nvim_set_current_win(orig_win)
      vim.cmd("diffthis")
    end
  end)
end

return M
