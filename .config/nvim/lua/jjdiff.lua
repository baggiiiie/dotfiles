local revs = vim.g.jjdiff_revs or {}
local rel = vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.")
local ft = vim.bo.filetype

for _, rev in ipairs(revs) do
  local out = vim.fn.systemlist({ "jj", "file", "show", "-r", rev, rel })
  if vim.v.shell_error == 0 then
    vim.cmd("vsplit")
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = ft
    vim.api.nvim_buf_set_name(buf, rel .. " @ " .. rev)
    vim.cmd("diffthis")
  end
end

vim.cmd("wincmd t")
vim.cmd("diffthis")
