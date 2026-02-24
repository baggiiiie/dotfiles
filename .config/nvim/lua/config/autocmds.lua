-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto-detect shell scripts without extension by analyzing content
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*",
  callback = function()
    local filename = vim.fn.expand("%:t")

    -- Only apply to files without extension
    if filename:match("%.") then
      return
    end

    -- Skip .env files
    if filename == ".env" or filename:match("^%.env%.") then
      return
    end

    -- Check first 30 lines for shell script indicators
    local lines = vim.fn.getline(1, 30)

    -- Ensure lines is a table
    if type(lines) == "string" then
      lines = { lines }
    end

    -- Shell script patterns to match
    local shell_patterns = {
      "^#!.*sh$", -- Shebang line
      "^%s*if%s+%[", -- if statements with [
      "^%s*for%s+", -- for loops
      "^%s*while%s+", -- while loops
      "^%s*function%s+", -- function declarations
      "^%s*case%s+", -- case statements
    }

    for _, line in ipairs(lines) do
      for _, pattern in ipairs(shell_patterns) do
        if line:match(pattern) then
          vim.bo.filetype = "sh"
          return
        end
      end
    end
  end,
})

vim.api.nvim_create_user_command("Ft", function(opts)
  vim.bo.filetype = opts.args
end, { nargs = 1 })

-- Disable diagnostics and formatting for markdown files
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("markdown_disable_features", { clear = true }),
  pattern = { "markdown" },
  callback = function()
    vim.b.autoformat = false
    vim.diagnostic.enable(false, { bufnr = 0 })
  end,
})

-- Soften diff colors (applied after colorscheme loads)
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("soften_diff_colors", { clear = true }),
  callback = function()
    vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#1a3a1a", fg = "NONE" })
    vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#3a1a1a", fg = "NONE" })
    vim.api.nvim_set_hl(0, "DiffChange", { bg = "#1a2a3a", fg = "NONE" })
    vim.api.nvim_set_hl(0, "DiffText", { bg = "#2a4a5a", fg = "NONE" })
  end,
})
