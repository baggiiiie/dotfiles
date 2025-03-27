return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      cssls = {
        init_options = {
          provideFormatter = false,
        },
      },
    },
  },
}
