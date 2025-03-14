-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = LazyVim.safe_keymap_set

-- clipboard is removed in options.lua
-- only allow 'y' to yank to clipboard
map({ "n", "x" }, "y", '"+y')
map("n", "p", '""p')

vim.keymap.set({ "c", "n", "i", "x", "v" }, "<C-a>", "<Home>", { desc = "Move to beginning of line" })
vim.keymap.set({ "c", "n", "i", "x", "v" }, "<C-e>", "<End>", { desc = "Move to end of line" })

function CopyRelativePath()
  local filepath = vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.")
  vim.fn.setreg("+", filepath) -- write to clipboard
end
vim.keymap.set(
  "n",
  "<leader>yp",
  CopyRelativePath,
  { noremap = true, silent = true, desc = "Copy relative path to clipboard" }
)
