local utils = require("plugins.bookmark_utils")
local M = {}

function M.setup(config)
	config.action("bookmark2", function()
		bookmark()
	end, {
		desc = "bookmark2",
		seq = { "w", "B" },
		scope = "revisions",
	})
end

function bookmark()
	local change_id = context.change_id()
	if not change_id then
		flash("No revision selected")
		return
	end

	local bookmarks = utils.get_bookmarks()

	if #bookmarks == 0 then
		flash("No bookmarks found")
		return
	end

	local selected = choose({ options = bookmarks, title = "Select bookmark", filter = true })
	if not selected then
		return
	end

	local op = choose({
		options = {
			"rename " .. selected,
			"delete " .. selected,
			"forget " .. selected,
			"move " .. selected,
			"show revision " .. selected,
		},
		title = "Select operation for " .. selected .. ": ",
	})
	if op then
		utils.perform_op(op, selected, change_id)
	end
end

return M
