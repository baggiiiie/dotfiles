-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
-- require("no-neck-pain")

-- https://github.com/golang/tools/blob/master/gopls/doc/vim.md
-- local lspconfig = require("lspconfig")
-- local configs = require("lspconfig/configs")
-- lspconfig.gopls.setup({
--   settings = {
--     gopls = {
--       analyses = {
--         unusedparams = true,
--       },
--       staticcheck = true,
--       gofumpt = true,
--     },
--   },
-- })
--
-- require("config.floaterm")

-- https://ast-grep.github.io/guide/tools/editors.html#neovim
require("lspconfig").ast_grep.setup({
  -- these are the default options, you only need to specify
  -- options you'd like to change from the default
  cmd = { "ast-grep", "lsp" },
  filetypes = {
    "c",
    "cpp",
    "rust",
    "go",
    "java",
    "python",
    "javascript",
    "typescript",
    "html",
    "css",
    "kotlin",
    "dart",
    "lua",
  },
  root_dir = require("lspconfig.util").root_pattern("sgconfig.yaml", "sgconfig.yml"),
})
