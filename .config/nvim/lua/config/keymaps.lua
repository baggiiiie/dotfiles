-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = LazyVim.safe_keymap_set

-- clipboard is removed in options.lua
-- only allow 'y' to yank to clipboard
map({ "n", "x" }, "y", '"+y')
map("n", "p", '""p')

-- Map ' to automatically center after jumping to mark
vim.keymap.set("n", "`", function()
  local mark = vim.fn.nr2char(vim.fn.getchar())
  vim.cmd("normal! `" .. mark .. "zz")
end, { noremap = true, silent = true })
vim.keymap.set("n", "G", function()
  vim.cmd("normal! G")
  vim.cmd("normal! zz")
end, { noremap = true })

-- easier editing
-- vim.keymap.set({ "c", "n", "x", "v" }, "<C-a>", "^", { desc = "Move to beginning of line" })
vim.keymap.set("i", "<C-a>", "<esc>I", { desc = "Move to beginning of line" })
-- vim.keymap.set({ "c", "n", "x", "v" }, "<C-e>", "$", { desc = "Move to end of line" })
vim.keymap.set("i", "<C-e>", "<esc>A", { desc = "Move to end of line" })
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

local function confirm_and_delete_buffer()
  local confirm = vim.fn.confirm("Delete buffer and file?", "&Yes\n&No", 2)

  if confirm == 1 then
    os.remove(vim.fn.expand("%"))
    vim.api.nvim_buf_delete(0, { force = true })
  end
end
vim.keymap.set("n", "<leader>fd", confirm_and_delete_buffer)

vim.keymap.set("x", "S", "<Plug>(nvim-surround-visual)")
