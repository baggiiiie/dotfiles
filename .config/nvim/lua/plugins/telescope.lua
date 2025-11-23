return {
  "nvim-telescope/telescope.nvim",
  keys = {
    { "<leader>fm", ":Telescope marks mark_type=local<CR>", desc = "Find marks in current buffer" },
    {
      "<leader>tr",
      function()
        require("telescope.builtin").resume()
      end,
      desc = "Resume last telescope search",
    },
  },
  opts = function()
    local actions = require("telescope.actions")
    local layout = require("telescope.actions.layout")
    return {
      pickers = {
        buffers = {
          mappings = {
            n = { ["d"] = actions.delete_buffer + actions.move_to_top },
            i = { ["<c-d>"] = actions.delete_buffer + actions.move_to_top },
          },
        },
      },
      defaults = {
        layout_strategy = vim.o.lines > 100 and "vertical" or "horizontal",
        preview = { hide_on_startup = false },
        layout_config = {
          flex = { flip_columns = 80 },
          horizontal = {
            preview_width = 0.7,
            width = 0.95,
            height = 0.85,
            prompt_position = "top",
          },
          vertical = {
            preview_height = 0.5,
            width = 0.95,
            height = 0.85,
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
          },
          i = {
            ["<C-p>"] = layout.toggle_preview,
          },
        },
      },
    }
  end,
}
