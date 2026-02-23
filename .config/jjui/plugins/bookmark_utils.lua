local unpack = table.unpack or unpack
local M = {}

M.template = 'if(self.present() && !remote, self.name() ++ "\n", "")'

function M.get_bookmarks(rev)
	local args = { "bookmark", "list", "-T", M.template }
	if rev then
		table.insert(args, "-r")
		table.insert(args, rev)
	end

	local output = jj(unpack(args))
	local bookmarks = {}
	for line in output:gmatch("[^\n]+") do
		if line ~= "" then
			table.insert(bookmarks, line)
		end
	end
	return bookmarks
end

function M.perform_op(op, bookmark, current_change_id)
	if string.find(op, "copy") then
		copy_to_clipboard(bookmark)
		flash("Copied bookmark: " .. bookmark)
	elseif string.find(op, "rename") then
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
	elseif string.find(op, "move") then
		local target = current_change_id
		if not target or string.find(op, "move " .. bookmark) then
			target = input({ title = "Move bookmark to (change ID)", value = current_change_id or "" })
		end

		if target and target ~= "" then
			local _, err = jj("bookmark", "move", bookmark, "--to", target, "--allow-backwards")
			if err ~= nil then
				flash("Error moving bookmark: " .. err)
			else
				flash("Moved bookmark " .. bookmark .. " to " .. target)
				revisions.refresh()
			end
		end
	elseif string.find(op, "show") then
		flash("Showing revision: " .. bookmark)
		revset.set("trunk()::" .. bookmark)
	end
end

return M
