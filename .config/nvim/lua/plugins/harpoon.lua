-- local harpoon = require("my-harpoon")
--
-- -- basic telescope configuration
-- -- local conf = require("telescope.config").values
-- -- local function toggle_telescope(harpoon_files)
-- --   local file_paths = {}
-- --   for _, item in ipairs(harpoon_files.items) do
-- --     table.insert(file_paths, item.value)
-- --   end
-- --
-- --   require("telescope.pickers")
-- --     .new({}, {
-- --       prompt_title = "Harpoon",
-- --       finder = require("telescope.finders").new_table({
-- --         results = file_paths,
-- --       }),
-- --       -- previewer = conf.file_previewer({}),
-- --       sorter = conf.generic_sorter({}),
-- --     })
-- --     :find()
-- -- end
-- --
-- -- vim.keymap.set("n", "<C-e>", function()
-- --   toggle_telescope(harpoon:list())
-- -- end, { desc = "Open harpoon window" })
-- --
-- vim.keymap.set("n", "<leader>ha", function()
--   harpoon:list():add()
-- end, { desc = "Add to harpoon" })
--
-- vim.keymap.set("n", "<leader>hd", function()
--   harpoon:list():remove()
-- end, { desc = "Remove from harpoon" })
--
-- vim.keymap.set("n", "<leader>hq", function()
--   harpoon:list():select(1)
-- end)
-- vim.keymap.set("n", "<leader>hw", function()
--   harpoon:list():select(2)
-- end)
-- vim.keymap.set("n", "<leader>hf", function()
--   harpoon:list():select(3)
-- end)
-- vim.keymap.set("n", "<leader>hp", function()
--   harpoon:list():select(4)
-- end)
--
-- -- Toggle previous & next buffers stored within Harpoon list
-- vim.keymap.set("n", "<C-P>", function()
--   harpoon:list():prev()
-- end)
-- vim.keymap.set("n", "<C-N>", function()
--   harpoon:list():next()
-- end)
--
-- -- Custom function to open Harpoon as a left split
-- local function harpoon_left_split()
--   print("hello from harpoon")
--   -- Calculate 30% of screen width
--   local width = math.floor(vim.o.columns * 0.3)
--
--   -- Create a vertical split on the left
--   vim.cmd("topleft " .. width .. "vsplit")
--
--   local list = harpoon:list()
--   -- print(list.items[1])
--   -- Open harpoon menu in the new split
--   -- require("harpoon.ui").toggle_quick_menu(list)
-- end
--
-- -- Set up your keybinding to use the custom function
-- vim.keymap.set("n", "<leader>t", harpoon_left_split, { desc = "Harpoon menu (left split)" })
--
-- harpoon:setup({})
--
-- harpoon:extend({
--   UI_CREATE = function(cx)
--     vim.keymap.set("n", "<C-v>", function()
--       harpoon.ui:select_menu_item({ vsplit = true })
--     end, { buffer = cx.bufnr })
--
--     -- vim.keymap.set("n", "<C-x>", function()
--     --   harpoon.ui:select_menu_item({ split = true })
--     -- end, { buffer = cx.bufnr })
--   end,
-- })

return {
  "ThePrimeagen/harpoon",

  -- name = "my-harpoon",
  -- dir = "/Users/ydai/Desktop/repos/harpoon/",
  lazy = false,
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup({})
    vim.keymap.set("n", "<leader>H", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = "Add to harpoon" })
    vim.keymap.set("n", "<leader>ha", function()
      harpoon:list():add()
    end, { desc = "Add to harpoon" })

    vim.keymap.set("n", "<leader>hd", function()
      harpoon:list():remove()
    end, { desc = "Remove from harpoon" })

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
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
}
