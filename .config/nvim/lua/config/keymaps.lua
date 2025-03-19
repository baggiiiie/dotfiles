-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = LazyVim.safe_keymap_set

-- clipboard is removed in options.lua
-- only allow 'y' to yank to clipboard
map({ "n", "x" }, "y", '"+y')
map("n", "p", '""p')

-- easier editing
vim.keymap.set({ "c", "n", "i", "x", "v" }, "<C-a>", "<Home>", { desc = "Move to beginning of line" })
vim.keymap.set({ "c", "n", "i", "x", "v" }, "<C-e>", "<End>", { desc = "Move to end of line" })
vim.keymap.set("n", "<cr>", "o<esc>k", { desc = "Create new line in normal mode" })
vim.keymap.set("n", "<S-cr>", "O<esc>j", { desc = "Create new line in normal mode" })

-- horizontal scrolling
vim.keymap.set("n", "zl", function()
  local scroll_amount = math.floor(vim.api.nvim_win_get_width(0) / 3)
  return scroll_amount .. "zl"
end, { noremap = true, expr = true, silent = true, desc = "Scroll left by half screen" })
vim.keymap.set("n", "zh", function()
  local scroll_amount = math.floor(vim.api.nvim_win_get_width(0) / 3)
  return scroll_amount .. "zh"
end, { noremap = true, expr = true, silent = true, desc = "Scroll right by half screen" })

-- Copy full path
function CopyFullPath()
  local filepath = vim.fn.fnamemodify(vim.fn.expand("%"), ":p")
  vim.fn.setreg("+", filepath) -- write to clipboard
end
vim.keymap.set("n", "<leader>yf", CopyFullPath, { noremap = true, silent = true, desc = "Copy full path to clipboard" })

-- Copy relative path
function CopyRelativePath()
  local filepath = vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.")
  vim.fn.setreg("+", filepath) -- write to clipboard
end
vim.keymap.set(
  "n",
  "<leader>yr",
  CopyRelativePath,
  { noremap = true, silent = true, desc = "Copy relative path to clipboard" }
)

-- telescope resume to last search
vim.keymap.set(
  "n",
  "<leader>tr",
  require("telescope.builtin").resume,
  { noremap = true, silent = true, desc = "Resume last telescope search" }
)

vim.keymap.set(
  "n",
  "<leader>ff",
  ":Telescope file_browser<CR>",
  { noremap = true, silent = true, desc = "File Browser from cwd" }
)
