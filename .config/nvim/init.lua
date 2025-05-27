-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
-- require("lspconfig").cucumber_language_server.setup()
-- https://github.com/golang/tools/blob/master/gopls/doc/vim.md
local lspconfig = require("lspconfig")
lspconfig.gopls.setup({
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
      },
      staticcheck = true,
      gofumpt = true,
    },
  },
})
require("no-neck-pain")

-- vim.cmd([[
--     set runtimepath^=~/.vim runtimepath+=~/.vim/after
--     let &packpath = &runtimepath
--     source ~/.vimrc
-- ]])
