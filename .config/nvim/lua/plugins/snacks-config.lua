-- https://github.com/folke/snacks.nvim/blob/main/docs/styles.md
return {
  "folke/snacks.nvim",
  opts = {
    styles = {
      lazygit = {
        width = 0.95,
        height = 0.95,
      },
      zen = {
        enter = true,
        fixbuf = false,
        minimal = false,
        width = 120,
        height = 0,
        backdrop = { transparent = false, blend = 70 },
        keys = { q = false },
        zindex = 40,
        wo = {
          winhighlight = "NormalFloat:Normal",
        },
        w = {
          snacks_main = true,
        },
      },
    },
  },
}
