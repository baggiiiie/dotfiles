-- Multi-grep picker for Telescope with file glob support
-- Usage: Type "search_term  file_pattern" (two spaces as separator)
-- Example: "function  *.lua" searches for "function" in all Lua files

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local make_entry = require("telescope.make_entry")
local conf = require("telescope.config").values

-- Default ripgrep arguments for consistent search behavior
local RG_BASE_ARGS = {
  "--color=never",
  "--no-heading",
  "--with-filename",
  "--line-number",
  "--column",
  "--smart-case",
  "--hidden",
  "--glob=!.git",
  "--glob=!.jj",
}

local function live_multigrep(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()

  local finder = finders.new_async_job({
    command_generator = function(prompt)
      if not prompt or prompt == "" then
        return nil
      end

      -- Split prompt by double space: "pattern  glob"
      local pieces = vim.split(prompt, "  ")
      local args = { "rg" }

      -- Add search pattern
      if pieces[1] and pieces[1] ~= "" then
        table.insert(args, "-e")
        table.insert(args, pieces[1])
      end

      -- Add file glob filter
      if pieces[2] and pieces[2] ~= "" then
        table.insert(args, "-g")
        table.insert(args, pieces[2])
      end

      -- Combine command args with base args
      return vim.iter({ args, RG_BASE_ARGS }):flatten():totable()
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  })

  pickers
    .new(opts, {
      debounce = 100,
      prompt_title = "Multi Grep",
      finder = finder,
      previewer = conf.grep_previewer(opts),
      sorter = require("telescope.sorters").empty(),
    })
    :find()
end

return live_multigrep
