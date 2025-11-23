return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      ast_grep = {
        cmd = { "ast-grep", "lsp" },
        filetypes = { "c", "cpp", "rust", "go", "java", "python", "javascript", "typescript", "html", "css", "kotlin", "dart", "lua" },
        root_dir = function(fname)
          return require("lspconfig.util").root_pattern("sgconfig.yaml", "sgconfig.yml")(fname)
        end,
      },
    },
  },
}
