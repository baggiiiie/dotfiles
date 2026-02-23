local utils = require("plugins.bookmark_utils")
local M = {}

function M.setup(config)
	config.action("bookmark", function()
		bookmark()
	end, {
		desc = "bookmark",
		seq = { "w", "b" },
		scope = "revisions",
	})
end

function bookmark()
	local change_id = context.change_id()
	if change_id == nil then
		flash("No revision selected")
		return
	end

	local bookmarks = utils.get_bookmarks(change_id)

	local function show_ops(b)
		local op = choose({
			options = { "rename " .. b, "delete " .. b, "forget " .. b, "copy " .. b, "show " .. b },
			title = "Select operation for " .. b .. ": ",
			ordered = true,
		})
		if op then
			utils.perform_op(op, b, change_id)
		end
	end

	if #bookmarks == 0 then
		local action = choose({
			options = { "create bookmark", "move bookmark" },
			title = "No bookmarks on revision",
			ordered = true,
		})
		if not action then
			return
		end

		if action == "create bookmark" then
			local name = input({ title = "New bookmark name" })
			if name and name ~= "" then
				jj("bookmark", "create", name, "-r", change_id)
				revisions.refresh()
			end
		elseif action == "move bookmark" then
			local all_bookmarks = utils.get_bookmarks()
			if #all_bookmarks == 0 then
				flash("No bookmarks to move")
				return
			end
			local to_move = choose({
				options = all_bookmarks,
				title = "Select bookmark to move",
				filter = true,
				ordered = true,
			})
			if to_move then
				utils.perform_op("move", to_move, change_id)
			end
		end
	elseif #bookmarks == 1 then
		show_ops(bookmarks[1])
	else
		local selected = choose({ options = bookmarks, title = "Select bookmark", ordered = true })
		if selected then
			show_ops(selected)
		end
	end
end

return M
