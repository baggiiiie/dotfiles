return {
  "shortcuts/no-neck-pain.nvim",
  version = "*",
  keys = {
    {
      "<leader>zs",
      function()
        require("no-neck-pain").toggle()
      end,
      desc = "toggle NoNeckPain",
    },
  },
}
