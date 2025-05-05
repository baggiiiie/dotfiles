-- Global variable to track sidebar state
_G.sidebar_open = false
_G.sidebar_winid = nil

-- Function to create a left sidebar scratch buffer (30% width)
function Create_Left_Sidebar()
  local screen_width = vim.o.columns
  local sidebar_width = math.floor(screen_width * 0.2)
  local current_winid = vim.api.nvim_get_current_win()

  -- Create new buffer on the left most window
  vim.cmd("wincmd t")
  vim.cmd("leftabove vertical new")
  _G.sidebar_winid = vim.api.nvim_get_current_win()
  -- Set scratch buffer properties
  vim.cmd("setlocal buftype=nofile")
  vim.cmd("setlocal bufhidden=hide")
  vim.cmd("setlocal noswapfile")
  vim.cmd("setlocal nobuflisted")
  vim.cmd("vertical resize " .. sidebar_width)

  vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = "no"
  vim.wo.cursorline = false
  vim.wo.cursorcolumn = false
  vim.opt_local.colorcolumn = ""
  vim.opt_local.modifiable = false

  vim.api.nvim_set_current_win(current_winid)

  _G.sidebar_open = true
end

function Toggle_Sidebar()
  if _G.sidebar_open then
    -- Try to close the sidebar if it exists
    if _G.sidebar_winid and vim.api.nvim_win_is_valid(_G.sidebar_winid) then
      vim.api.nvim_win_close(_G.sidebar_winid, true)
    else
      -- If window ID is invalid, find and close the leftmost window
      vim.print("invalid sidebar window ID")
    end
    _G.sidebar_open = false
    _G.sidebar_winid = nil
  else
    Create_Left_Sidebar()
  end
end

vim.api.nvim_create_user_command("ToggleSidebar", Toggle_Sidebar, {})

vim.keymap.set("n", "<Leader>zs", Toggle_Sidebar, { noremap = true, silent = true, desc = "Toggle sidebar" })

vim.api.nvim_create_autocmd({ "WinNew" }, {
  callback = function()
    if _G.sidebar_open then
      vim.print("new window created, imma close the sidebar now")
      vim.api.nvim_win_close(_G.sidebar_winid, true)
      _G.sidebar_open = false
    end
  end,
})
