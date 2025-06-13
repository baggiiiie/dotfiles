-- some reference: https://github.com/soer9459/NeoVim/blob/main/lua/user/plugins/telescope.lua

-- NOTE: please use :h Telescope to save myself hours

local actions = require("telescope.actions")
local layout = require("telescope.actions.layout")
local builtin = require("telescope.builtin")
return {
  "nvim-telescope/telescope.nvim",

  keys = {

    {
      "<leader>ff",
      ":Telescope file_browser<CR>",
      desc = "File Browser from cwd",
    },
    {
      "<leader>fm",
      ":Telescope marks mark_type=local<CR>",
      desc = "Find marks in current buffer",
    },
    {
      "<leader>tr",
      builtin.resume,
      desc = "Resume last telescope search",
    },
    {
      "<leader>fF",
      ":Telescope file_browser path=%:p:h select_buffer=true<CR>",
      desc = "File Browser from current buffer",
    },
  },
  opts = {
    pickers = {
      buffers = {
        mappings = {
          n = {
            ["d"] = actions.delete_buffer + actions.move_to_top,
          },
          i = {
            ["<c-d>"] = actions.delete_buffer + actions.move_to_top,
          },
        },
      },
    },
    defaults = {
      -- layout_strategy = "flex",
      -- for some reason flex doesn't give vertical preview?
      layout_strategy = vim.o.lines > 100 and "vertical" or "horizontal",
      preview = { hide_on_startup = false },
      layout_config = {
        flex = { flip_columns = 80 },
        horizontal = {
          preview_width = 0.7, -- Increase preview width (0.5 = 50% of window width)
          width = 0.95, -- Make the whole Telescope window larger
          height = 0.85, -- Increase the height of the Telescope popup
          prompt_position = "top",
        },
        vertical = {
          preview_height = 0.5, -- Increase preview width (0.5 = 50% of window width)
          width = 0.95, -- Make the whole Telescope window larger
          height = 0.85, -- Increase the height of the Telescope popup
          prompt_position = "top",
        },
      },
      sorting_strategy = "ascending",
      path_display = { "filename_first" },
      dynamic_preview_title = true,
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
