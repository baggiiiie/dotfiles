return {
  "shortcuts/no-neck-pain.nvim",
  version = "*",
  keys = {
    -- below has been updated in `keymaps.lua`
    --     {
    --       "<leader>ff",
    --       ":Telescope file_browser<CR>",
    --       desc = "File Browser from cwd",
    --     },
    {
      "<leader>zs",
      function()
        require("no-neck-pain").toggle()
      end,
      desc = "toggle NoNeckPain",
    },
  },
}
