local revs = vim.g.jjdiff_revs or {}
local file = vim.api.nvim_buf_get_name(0)

if file == "" then
  vim.notify("Current buffer has no file", vim.log.levels.ERROR, { title = "jjdiff" })
  return
end

local abs_path = vim.fs.normalize(vim.fn.fnamemodify(file, ":p"))
local file_dir = vim.fs.dirname(abs_path)
local ft = vim.bo.filetype
local root_cmd = vim.system({ "jj", "root" }, { cwd = file_dir, text = true }):wait()

if root_cmd.code ~= 0 then
  local err = (root_cmd.stderr or root_cmd.stdout or "Not inside a jj repo"):gsub("%s+$", "")
  vim.notify(err, vim.log.levels.ERROR, { title = "jjdiff" })
  return
end

local repo_root_raw = (root_cmd.stdout or ""):gsub("%s+$", "")
local repo_root = vim.fs.normalize(repo_root_raw)
local rel = vim.fs.relpath(repo_root, abs_path)
if not rel then
  vim.notify(string.format("Path %q is not inside jj repo %q", abs_path, repo_root), vim.log.levels.ERROR, {
    title = "jjdiff",
  })
  return
end

for _, rev in ipairs(revs) do
  local cmd = vim.system({ "jj", "file", "show", "-r", rev, rel }, {
    cwd = repo_root,
    text = true,
  }):wait()

  if cmd.code == 0 then
    local out = vim.split(cmd.stdout or "", "\n", { plain = true })
    if out[#out] == "" then
      table.remove(out)
    end

    vim.cmd("vsplit")
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = ft
    vim.api.nvim_buf_set_name(buf, rel .. " @ " .. rev)
    vim.cmd("diffthis")
  else
    local err = (cmd.stderr or cmd.stdout or "jj file show failed"):gsub("%s+$", "")
    vim.notify(err, vim.log.levels.ERROR, { title = "jjdiff" })
  end
end

vim.cmd("wincmd t")
vim.cmd("diffthis")
