local M = {}
function M.setup(config)
	config.action("commit", function()
		local applied = revisions.start_inline_describe()
		if applied then
			jj("new", "-A", context.change_id())
			revisions.refresh()
			local new_change_id = jj("log", "-r", "@", "-T", "change_id.shortest()", "--no-graph")
			revisions.navigate({ to = new_change_id })
			return
		end
	end, {
		desc = "commit",
		key = { "c" },
		scope = "revisions",
	})
end

return M
