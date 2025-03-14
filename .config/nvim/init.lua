-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
-- require("lspconfig").cucumber_language_server.setup()

-- vim.cmd([[
--     set runtimepath^=~/.vim runtimepath+=~/.vim/after
--     let &packpath = &runtimepath
--     source ~/.vimrc
-- ]])

vim.keymap.set("n", "zl", function()
  local scroll_amount = math.floor(vim.api.nvim_win_get_width(0) / 2)
  return scroll_amount .. "zl"
end, { noremap = true, expr = true, silent = true })

vim.keymap.set("n", "zh", function()
  local scroll_amount = math.floor(vim.api.nvim_win_get_width(0) / 2)
  return scroll_amount .. "zh"
end, { noremap = true, expr = true, silent = true })
