-- some reference: https://github.com/soer9459/NeoVim/blob/main/lua/user/plugins/telescope.lua

-- NOTE: please use :h Telescope to save myself hours

local actions = require("telescope.actions")
local layout = require("telescope.actions.layout")
return {
  "nvim-telescope/telescope.nvim",

  opts = {
    pickers = {
      buffers = {
        mappings = {
          i = {
            ["<c-d>"] = actions.delete_buffer + actions.move_to_top,
          },
        },
      },
    },
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
          ["p"] = layout.toggle_preview,
          ["<C-p>"] = layout.toggle_preview,
          -- ["<C-c>"] = require("telescope.actions").close,
        },
        i = {
          ["<C-p>"] = layout.toggle_preview,
        },
      },
    },
  },
}
