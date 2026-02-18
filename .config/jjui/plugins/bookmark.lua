local M = {}
function M.setup(config)
	config.action("bookmark2", function()
		bookmark()
	end, {
		desc = "bookmark",
		seq = { "w", "b" },
		scope = "revisions",
	})
end

function bookmark()
	-- Get the current revision's change_id
	template = 'if(self.present() && !remote, self.name() ++ "\n", "")'
	local change_id = context.change_id()
	if not change_id then
		flash("No revision selected")
		return
	end

	-- Get bookmarks on this revision
	local output = jj("bookmark", "list", "-r", change_id, "-T", template)
	local bookmarks = {}
	for line in output:gmatch("[^\n]+") do
		if line ~= "" then
			table.insert(bookmarks, line)
		end
	end

	local function bookmark_operations(bookmark)
		local op = choose({
			options = { "rename " .. bookmark, "delete " .. bookmark, "forget " .. bookmark },
			title = "Select operation: ",
		})
		if not op then
			return
		end

		if string.find(op, "rename") then
			local new_name = input({ title = "New bookmark name", value = bookmark })
			if new_name and new_name ~= "" then
				jj("bookmark", "rename", bookmark, new_name)
				revisions.refresh()
			end
		elseif string.find(op, "delete") then
			jj("bookmark", "delete", bookmark)
			revisions.refresh()
		elseif string.find(op, "forget") then
			jj("bookmark", "forget", bookmark)
			revisions.refresh()
		end
	end

	if #bookmarks == 0 then
		-- No bookmarks: show create/move menu
		local action = choose({ options = { "create bookmark", "move bookmark" }, title = "No bookmarks on revision" })
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
			-- Get all bookmarks to move one here
			local all_output = jj("bookmark", "list", "-T", template)
			local all_bookmarks = {}
			for line in all_output:gmatch("[^\n]+") do
				if line ~= "" then
					table.insert(all_bookmarks, line)
				end
			end
			if #all_bookmarks == 0 then
				flash("No bookmarks to move")
				return
			end
			local to_move = choose({ options = all_bookmarks, { title = "Select bookmark to move" }, filter = true })
			if to_move then
				local move_res, err = jj("bookmark", "move", to_move, "--to", change_id, "--allow-backwards")
				if err ~= nil then
					flash("Error moving bookmark: " .. err)
				else
					flash("Moved bookmark " .. move_res)
					revisions.refresh()
				end
			end
		end
	elseif #bookmarks == 1 then
		-- Single bookmark: show operations directly
		bookmark_operations(bookmarks[1])
	else
		-- Multiple bookmarks: let user pick one first
		local selected = choose({ options = bookmarks, title = "Select bookmark" })
		if selected then
			bookmark_operations(selected)
		end
	end
end

return M
