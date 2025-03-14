return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = function(_, opts)
    opts.defaults = opts.defaults or {}
    opts.defaults.layout_strategy = "horizontal"
    opts.defaults.layout_config = {
      preview_width = 0.7,
      width = 0.9,
      height = 0.8,
    }

    -- Custom function to show relative paths with line numbers in LSP references
    local telescope = require("telescope.builtin")
    function Show_relative_paths_with_lines()
      telescope.lsp_references({
        show_line = false, -- Hides the actual line of code
        entry_maker = function(entry)
          local relpath = vim.fn.fnamemodify(entry.filename, ":.") -- Get relative path
          local line_info = string.format(":%d", entry.lnum) -- Get line number
          local display_text = relpath .. line_info -- Format as "relative/path/to/file:line"
          return {
            value = entry,
            ordinal = display_text,
            display = display_text, -- Show relative path with line number
            filename = entry.filename,
            lnum = entry.lnum,
          }
        end,
      })
    end

    -- Override default keymap for "Go to References"
    -- vim.keymap.set(
    --   "n",
    --   "<leader>gr",
    --   Show_relative_paths_with_lines,
    --   { desc = "Show References (Relative Paths + Line Numbers)", noremap = true, silent = true }
    -- )
    -- vim.keymap.set(
    --   "n",
    --   "gr",
    --   Show_relative_paths_with_lines,
    --   { desc = "Show References (Relative Paths + Line Numbers)", noremap = true, silent = true }
    -- )
  end,
  keys = {
    -- disable the keymap to grep files
    { "gr", Show_relative_paths_with_lines, desc = "please.." },
  },
}
