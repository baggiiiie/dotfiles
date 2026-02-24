local utils = require("plugins.bookmark_utils")
local M = {}

local bookmark_template = 'if(self.present() && !remote, self.name() ++ ";" ++ normal_target.commit_id().shortest(8) ++ "\n", "")'

function M.setup(config)
	config.action("bookmark_view", function()
		bookmark_view()
	end, {
		desc = "interactive bookmark view",
		seq = { "w", "i" },
		scope = "revisions",
	})
end

local function get_bookmark_entries()
	local output = jj("bookmark", "list", "-T", bookmark_template)
	local entries = {}

	for line in output:gmatch("[^\n]+") do
		local name, commit_id = line:match("^([^;]+);([^;]+)$")
		if name and name ~= "" then
			table.insert(entries, {
				name = name,
				commit_id = commit_id or "",
				label = string.format("%-36s %s", name, commit_id or ""),
			})
		end
	end

	return entries
end

local function choose_bookmark(entries)
	local options = {}
	local by_label = {}

	for _, entry in ipairs(entries) do
		table.insert(options, entry.label)
		by_label[entry.label] = entry
	end

	local selected = choose({
		options = options,
		title = "Bookmarks",
		filter = true,
		ordered = true,
	})

	if not selected then
		return nil
	end

	return by_label[selected]
end

local function choose_operation(entry, current_change_id)
	local options = {
		"edit " .. entry.name,
		"new from " .. entry.name,
		"rename " .. entry.name,
		"delete " .. entry.name,
		"forget " .. entry.name,
		"copy " .. entry.name,
		"show " .. entry.name,
		"go to branch on github",
	}

	if current_change_id then
		table.insert(options, 6, "move " .. entry.name .. " to selected revision")
	end

	return choose({
		options = options,
		title = entry.name,
		ordered = true,
	})
end

local function perform_view_op(op, entry, current_change_id)
	if op == "edit " .. entry.name then
		local _, err = jj("edit", "-r", entry.name)
		if err ~= nil then
			flash({ text = "Error editing bookmark: " .. err, error = true })
			return false
		end
		revisions.refresh({ selected_revision = "@" })
		return true
	elseif op == "new from " .. entry.name then
		local _, err = jj("new", entry.name)
		if err ~= nil then
			flash({ text = "Error creating revision from bookmark: " .. err, error = true })
			return false
		end
		revisions.refresh({ selected_revision = "@" })
		return true
	elseif op == "move " .. entry.name .. " to selected revision" then
		utils.perform_op("move", entry.name, current_change_id)
		return false
	else
		utils.perform_op(op, entry.name, current_change_id)
		return op == "show " .. entry.name
	end
end

function bookmark_view()
	local current_change_id = context.change_id()

	while true do
		local entries = get_bookmark_entries()
		if #entries == 0 then
			flash({ text = "No local bookmarks found", error = true })
			return
		end

		local entry = choose_bookmark(entries)
		if not entry then
			return
		end

		local op = choose_operation(entry, current_change_id)
		if not op then
			return
		end

		if perform_view_op(op, entry, current_change_id) then
			return
		end
	end
end

return M
