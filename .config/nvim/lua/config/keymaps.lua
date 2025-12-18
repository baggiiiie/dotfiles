-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = LazyVim.safe_keymap_set

-- Clipboard: only allow 'y' to yank to clipboard (clipboard removed in options.lua)
map({ "n", "x" }, "y", '"+y')
map("n", "p", '""p')

-- Easier editing in insert mode
vim.keymap.set("i", "<C-a>", "<esc>I", { desc = "Move to beginning of line" })
vim.keymap.set("i", "<C-e>", "<esc>A", { desc = "Move to end of line" })

-- Create new lines in normal mode
vim.keymap.set("n", "<cr>", "o<esc>k", { desc = "Create new line below" })
vim.keymap.set("n", "<S-cr>", "O<esc>j", { desc = "Create new line above" })
-- Horizontal scrolling (1/3 of window width)
local function scroll_right()
  return math.floor(vim.api.nvim_win_get_width(0) / 3) .. "zl"
end

local function scroll_left()
  return math.floor(vim.api.nvim_win_get_width(0) / 3) .. "zh"
end

vim.keymap.set("n", "zl", scroll_right, { noremap = true, expr = true, silent = true, desc = "Scroll right by 1/3 screen" })
vim.keymap.set("n", "zh", scroll_left, { noremap = true, expr = true, silent = true, desc = "Scroll left by 1/3 screen" })

-- File path utilities
local function copy_full_path()
  local filepath = vim.fn.fnamemodify(vim.fn.expand("%"), ":p")
  vim.fn.setreg("+", filepath)
end

local function copy_relative_path()
  local filepath = vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.")
  vim.fn.setreg("+", filepath)
end

local function confirm_and_delete_buffer()
  local confirm = vim.fn.confirm("Delete buffer and file?", "&Yes\n&No", 2)
  if confirm == 1 then
    os.remove(vim.fn.expand("%"))
    vim.api.nvim_buf_delete(0, { force = true })
  end
end

vim.keymap.set("n", "<leader>yf", copy_full_path, { noremap = true, silent = true, desc = "Copy full path to clipboard" })
vim.keymap.set("n", "<leader>yr", copy_relative_path, { noremap = true, silent = true, desc = "Copy relative path to clipboard" })
vim.keymap.set("n", "<leader>fd", confirm_and_delete_buffer, { desc = "Delete buffer and file" })

-- Additional keymaps
vim.keymap.set("n", "<leader>/", require("config.multigrep"), { desc = "Multi grep in files" })
vim.keymap.set("x", "S", "<Plug>(nvim-surround-visual)", { desc = "Surround visual selection" })
vim.keymap.set("n", "<leader>gt", "<cmd>Gitsigns toggle_current_line_blame<cr>", { desc = "Toggle git blame" })

-- Disable AI assistants
vim.keymap.set("n", "<leader>cx", function()
  vim.cmd("Copilot disable")
  vim.cmd("SupermavenToggle")
  vim.notify("Copilot/Supermaven disabled for this session", vim.log.levels.INFO, { title = "AI Assistants" })
end, { desc = "Disable AI assistants" })

-- Terminal
map({ "n", "t" }, "<leader>tt", function()
  Snacks.terminal("zsh", { cwd = LazyVim.root() })
end, { desc = "Floating terminal" })

-- Development utilities
map("n", "<leader>rr", function()
  vim.cmd("luafile %")
end, { desc = "Run current Lua file" })

map("n", "<leader>gB", function()
  local filepath = vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.")
  local line = vim.fn.line(".")
  vim.fn.system("gh browse " .. filepath .. ":" .. line)
end, { desc = "Open file in GitHub" })
