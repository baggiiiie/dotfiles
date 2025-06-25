-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("no-neck-pain")

-- https://github.com/golang/tools/blob/master/gopls/doc/vim.md
local lspconfig = require("lspconfig")
local configs = require("lspconfig/configs")

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
