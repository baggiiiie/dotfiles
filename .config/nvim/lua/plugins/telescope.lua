-- some reference: https://github.com/soer9459/NeoVim/blob/main/lua/user/plugins/telescope.lua

-- NOTE: please use :h Telescope to save myself hours

return {
  "nvim-telescope/telescope.nvim",
  opts = {
    defaults = {
      layout_strategy = "flex",
      layout_config = {
        flex = { flip_columns = 100 },
        horizontal = {
          preview_width = 0.7, -- Increase preview width (0.5 = 50% of window width)
          width = 0.9, -- Make the whole Telescope window larger
          height = 0.8, -- Increase the height of the Telescope popup
        },
      },
      path_display = { "filename_first" },
      mappings = {
        n = {
          ["p"] = require("telescope.actions.layout").toggle_preview,
          ["<C-p>"] = require("telescope.actions.layout").toggle_preview,
          -- ["<C-c>"] = require("telescope.actions").close,
        },
        i = {
          ["<C-p>"] = require("telescope.actions.layout").toggle_preview,
        },
      },
    },
  },
}
