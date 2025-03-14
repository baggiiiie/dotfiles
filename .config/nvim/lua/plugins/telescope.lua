return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local telescope = require("telescope")
    local builtin = require("telescope.builtin")

    -- Your relative path formatter function
    local function format_relative_path(filename, lnum)
      local relpath = vim.fn.fnamemodify(filename, ":.")
      local line_info = string.format(":%d", lnum)
      return relpath .. line_info
    end

    -- Apply to specific builtin functions
    local original_lsp_references = builtin.lsp_references
    builtin.lsp_references = function(opts)
      opts = opts or {}
      opts.show_line = false
      opts.entry_maker = function(entry)
        local display_text = format_relative_path(entry.filename, entry.lnum)
        return {
          value = entry,
          ordinal = display_text,
          display = display_text,
          filename = entry.filename,
          lnum = entry.lnum,
        }
      end
      original_lsp_references(opts)
    end

    -- Do the same for other pickers you frequently use
    local original_live_grep = builtin.live_grep
    builtin.live_grep = function(opts)
      opts = opts or {}
      local original_entry_maker = opts.entry_maker
      opts.entry_maker = function(entry)
        if original_entry_maker then
          entry = original_entry_maker(entry)
        end
        if entry and entry.filename and entry.lnum then
          local display_text = format_relative_path(entry.filename, entry.lnum)
          entry.display = display_text
          entry.ordinal = display_text
        end
        return entry
      end
      original_live_grep(opts)
    end

    -- Setup telescope with your defaults
    telescope.setup({
      defaults = {
        layout_strategy = "horizontal",
        layout_config = {
          preview_width = 0.7,
          width = 0.9,
          height = 0.8,
        },
      },
    })

    -- You can keep your specific keybinding if needed
    vim.keymap.set("n", "gr", builtin.lsp_references, {
      desc = "Show References (Relative Paths + Line Numbers)",
    })
  end,
}
