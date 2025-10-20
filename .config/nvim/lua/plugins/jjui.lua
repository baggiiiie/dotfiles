return {
  "ReKylee/jjui.nvim",
  dependencies = { "folke/snacks.nvim" },
  -- `opts` will be passed to the setup function automatically
  -- https://github.com/ReKylee/jjui.nvim/blob/main/lua/jjui/config.lua
  opts = {
    executable = "jjui",
    keymaps = {
      toggle = "<leader>j",
    },
    terminal_opts = {
      win = {
        border = "rounded",
        width = 1,
        height = 1,
      },
    },
  },
}
