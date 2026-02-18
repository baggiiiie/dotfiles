local M = {}
function M.setup(config)
	config.action("open in vim", function()
		local file = context.file()
		if not file then
			flash("No file selected")
			return
		end
		exec_shell("nvim " .. file)
	end, {
		desc = "open in vim",
		key = { "O" },
		scope = "revisions.details",
	})
end

return M
