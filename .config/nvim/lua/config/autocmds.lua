-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile", "BufWritePost" }, {
  pattern = { "*" },
  callback = function()
    if vim.fn.getline(1):match("^#!.*sh$") then
      vim.bo.filetype = "sh"
    end
  end,
})

vim.api.nvim_create_user_command("Ft", function(opts)
  vim.bo.filetype = opts.args
end, { nargs = 1 })

-- vim.api.nvim_create_autocmd("BufWritePre", {
--   pattern = "*.go",
--   callback = function()
--     local params = vim.lsp.util.make_range_params()
--     params.context = { only = { "source.organizeImports" } }
--     -- buf_request_sync defaults to a 1000ms timeout. Depending on your
--     -- machine and codebase, you may want longer. Add an additional
--     -- argument after params if you find that you have to write the file
--     -- twice for changes to be saved.
--     -- E.g., vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
--     local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params)
--     for cid, res in pairs(result or {}) do
--       for _, r in pairs(res.result or {}) do
--         if r.edit then
--           local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
--           vim.lsp.util.apply_workspace_edit(r.edit, enc)
--         end
--       end
--     end
--     vim.lsp.buf.format({ async = false })
--   end,
-- })
