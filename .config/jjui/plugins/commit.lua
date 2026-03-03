local M = {}
function M.setup(config)
	config.action("commit", function()
		revisions.open_inline_describe()
		if not wait_close() then
			return
		end
		revisions.new()
		wait_refresh()
	end, {
		desc = "commit",
		key = { "c" },
		scope = "revisions",
	})
end

return M
