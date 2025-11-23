return {
  "rmagatti/auto-session",
  lazy = false,
  init = function()
    LazyVim.on_load("which-key.nvim", function()
      require("which-key").add({ { "<leader>a", group = "Auto Session" } })
    end)
  end,
  keys = {
    { "<leader>af", "<cmd>SessionSearch<CR>", desc = "Find a session" },
    {
      "<leader>as",
      function()
        local full_path = vim.fn.getcwd()
        local dir_name = full_path
        local session_name = vim.fn.input("Enter session name for: " .. dir_name)
        if session_name ~= "" then
          session_name = ":" .. session_name
        end
        vim.cmd(":SessionSave " .. dir_name .. session_name)
      end,
      desc = "Save a session",
    },
    { "<leader>aa", "<cmd>SessionToggleAutoSave<CR>", desc = "Toggle autosave" },
  },
  ---@module "auto-session"
  ---@type AutoSession.Config
  opts = {
    suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
    auto_restore_last_session = false,
    use_git_branch = true,
    show_auto_restore_notif = true,
    session_lens = {
      load_on_setup = true,
      previewer = false,
      mappings = {
        delete_session = { { "i", "n" }, "<C-D>" },
        alternate_session = { "i", "<C-S>" },
        copy_session = { "i", "<C-Y>" },
      },
      theme_conf = {
        border = true,
        layout_strategy = vim.o.lines > 100 and "vertical" or "horizontal",
        preview = { hide_on_startup = true },
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
      },
    },
  },
}
