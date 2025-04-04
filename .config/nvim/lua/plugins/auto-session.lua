local wk = require("which-key")
wk.add({
  { "<leader>a", group = "Auto Session" }, -- group
})

function SaveSessionWithName()
  -- Get the current working directory
  local full_path = vim.fn.getcwd()
  -- Extract just the directory name (last part of the path)
  local dir_name = vim.fn.fnamemodify(full_path, ":t")
  -- Prompt for the command to run
  local session_name = vim.fn.input("Enter session name for: " .. dir_name)
  local full_command = ":SessionSave " .. dir_name .. ":" .. session_name
  vim.cmd(full_command)
end

return {
  "rmagatti/auto-session",
  lazy = false,
  keys = {
    -- Will use Telescope if installed or a vim.ui.select picker otherwise
    { "<leader>ar", "<cmd>SessionSearch<CR>", desc = "Find a session" },
    { "<leader>as", SaveSessionWithName, desc = "Save a session" },
    { "<leader>aa", "<cmd>SessionToggleAutoSave<CR>", desc = "Toggle autosave" },
  },

  ---enables autocomplete for opts
  ---@module "auto-session"
  ---@type AutoSession.Config
  opts = {
    -- ⚠️ This will only work if Telescope.nvim is installed
    -- The following are already the default values, no need to provide them if these are already the settings you want.
    session_lens = {
      -- If load_on_setup is false, make sure you use `:SessionSearch` to open the picker as it will initialize everything first
      load_on_setup = true,
      previewer = false,
      mappings = {
        -- Mode can be a string or a table, e.g. {"i", "n"} for both insert and normal mode
        delete_session = { "i", "<C-D>" },
        alternate_session = { "i", "<C-S>" },
        copy_session = { "i", "<C-Y>" },
      },
      -- Can also set some Telescope picker options
      -- For all options, see: https://github.com/nvim-telescope/telescope.nvim/blob/master/doc/telescope.txt#L112
      theme_conf = {
        border = true,
        -- layout_config = {
        --   width = 0.8, -- Can set width and height as percent of window
        --   height = 0.5,
        -- },
      },
    },
  },
}
