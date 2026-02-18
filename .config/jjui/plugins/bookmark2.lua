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
	template = 'if(self.present() && !remote, self.name() ++ "\n", "")'
	local change_id = context.change_id()
	if not change_id then
		flash("No revision selected")
		return
	end

	-- Get all bookmarks
	local output = jj("bookmark", "list", "-T", template)
	local bookmarks = {}
	for line in output:gmatch("[^\n]+") do
		if line ~= "" then
			table.insert(bookmarks, line)
		end
	end

	if #bookmarks == 0 then
		flash("No bookmarks found")
		return
	end

	-- Let user pick a bookmark
	local selected = choose({ options = bookmarks, title = "Select bookmark", filter = true })
	if not selected then
		return
	end

	-- Show operations for selected bookmark
	local op = choose({
		options = {
			"rename " .. selected,
			"delete " .. selected,
			"forget " .. selected,
			"move " .. selected,
			"show revision " .. selected,
		},
		title = "Select operation: ",
	})
	if not op then
		return
	end

	if string.find(op, "rename") then
		local new_name = input({ title = "New bookmark name", value = selected })
		if new_name and new_name ~= "" then
			jj("bookmark", "rename", selected, new_name)
			revisions.refresh()
		end
	elseif string.find(op, "delete") then
		jj("bookmark", "delete", selected)
		revisions.refresh()
	elseif string.find(op, "forget") then
		jj("bookmark", "forget", selected)
		revisions.refresh()
	elseif string.find(op, "move") then
		local target = input({ title = "Move bookmark to (change ID)", value = change_id })
		if target and target ~= "" then
			local move_res, err = jj("bookmark", "move", selected, "--to", target, "--allow-backwards")
			if err ~= nil then
				flash("Error moving bookmark: " .. err)
			else
				flash("Moved bookmark " .. selected .. " to " .. target)
				revisions.refresh()
			end
		end
	elseif string.find(op, "show revision") then
		revset.set("trunk()::" .. selected)
	end
end

return M
