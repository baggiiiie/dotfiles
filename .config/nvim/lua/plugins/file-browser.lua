return {
  "nvim-telescope/telescope-file-browser.nvim",
  keys = {
    -- below has been updated in `keymaps.lua`
    --     {
    --       "<leader>ff",
    --       ":Telescope file_browser<CR>",
    --       desc = "File Browser from cwd",
    --     },
    {
      "<leader>fF",
      ":Telescope file_browser path=%:p:h select_buffer=true<CR>",
      desc = "File Browser from current buffer",
    },
  },
}
