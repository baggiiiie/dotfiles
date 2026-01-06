return {
  "shortcuts/no-neck-pain.nvim",
  version = "*",
  config = function()
    require("no-neck-pain").setup({
      buffers = {
        -- colors = { blend = 0.5 },
      },
      width = 120,
      autocmds = {
        -- enableOnVimEnter = "safe",
      },
    })
  end,
  keys = {
    {
      "<leader>zs",
      function()
        require("no-neck-pain").toggle()
      end,
      desc = "toggle NoNeckPain",
    },
    -- {
    --   "<leader>zw",
    --   function()
    --     require("no-neck-pain").resize(120)
    --   end,
    --   desc = "NoNeckPainResize to 120",
    -- },
  },
}
