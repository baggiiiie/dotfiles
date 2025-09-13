return {
  "baggiiiie/harpoon",
  name = "my-harpoon",
  branch = "my-harpoon",
  dependencies = { "nvim-lua/plenary.nvim" },
  -- dir = "/Users/ydai/Desktop/repos/personal/harpoon/",

  lazy = false,
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup({})
    vim.keymap.set("n", "<leader>H", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = "Open harpoon menu" })
    vim.keymap.set("n", "<leader>ha", function()
      harpoon:list():add()
    end, { desc = "Add current buffer to harpoon" })

    vim.keymap.set("n", "<leader>hd", function()
      harpoon:list():remove()
    end, { desc = "Remove current buffer from harpoon" })

    vim.keymap.set("n", "<leader>hh", function()
      harpoon:list():select(1)
    end)
    vim.keymap.set("n", "<leader>h,", function()
      harpoon:list():select(2)
    end)
    vim.keymap.set("n", "<leader>h.", function()
      harpoon:list():select(3)
    end)
    vim.keymap.set("n", "<leader>hn", function()
      harpoon:list():select(4)
    end)
    vim.keymap.set("n", "<leader>he", function()
      harpoon:list():select(5)
    end)
    vim.keymap.set("n", "<leader>hi", function()
      harpoon:list():select(6)
    end)
    vim.keymap.set("n", "<leader>hl", function()
      harpoon:list():select(7)
    end)
    vim.keymap.set("n", "<C-P>", function()
      harpoon:list():prev()
    end)
    vim.keymap.set("n", "<C-N>", function()
      harpoon:list():next()
    end)
  end,
}
