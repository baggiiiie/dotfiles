local M = {}
function M.setup(config)
	config.action("open in vim", function()
		local file = context.file()
		if not file then
			flash({ text = "No file selected", error = true })
			return
		end
		local change_id = context.change_id()
		local line = nil
		if change_id then
			local output, err = jj("diff", "-r", change_id, "--git", file, "--no-pager")
			if not err and output then
				line = output:match("@@ %S+ %+(%d+)")
			end
		end
		if line then
			exec_shell("nvim +" .. line .. " " .. file)
		else
			exec_shell("nvim " .. file)
		end
	end, {
		desc = "open in vim",
		key = { "O" },
		scope = "revisions.details",
	})
end

return M
