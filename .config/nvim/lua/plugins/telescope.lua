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
    -- Workaround: Telescope uses feedkeys("A") to enter insert mode, but for
    -- async pickers (LSP) the prompt buffer's auto-insert wins the race, so "A"
    -- is typed literally. Block it via InsertCharPre with a timing guard.
    {
      "<leader>ss",
      function()
        require("telescope.builtin").lsp_document_symbols({
          symbols = LazyVim.config.get_kind_filter(),
          attach_mappings = function(prompt_bufnr)
            local open_time = vim.uv.now()
            vim.api.nvim_create_autocmd("InsertCharPre", {
              buffer = prompt_bufnr,
              once = true,
              callback = function()
                if vim.v.char == "A" and (vim.uv.now() - open_time) < 200 then
                  vim.v.char = ""
                end
              end,
            })
            return true
          end,
        })
      end,
      desc = "Goto Symbol",
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
