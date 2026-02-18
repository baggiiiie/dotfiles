local M = {}

function M.setup(config)
	config.action("copy to clipboard", function()
		local change_id = context.change_id()
		if change_id then
			copy_to_clipboard(change_id)
			flash("Copied change ID: " .. change_id)
			return
		end
	end, {
		desc = "copy to clipboard",
		key = { "Y" },
		-- scope = { "revisions", "revisions.details" },
		scope = "revisions",
	})
	config.action("copy to clipboard - details", function()
		local checked_files = context.checked_files()
		if checked_files and next(checked_files) ~= nil then
			local file_names = table.concat(checked_files, " ")
			copy_to_clipboard(file_names)
			flash("Copied checked files: " .. file_names)
			return
		end
		local selected_file = context.file()
		if selected_file then
			copy_to_clipboard(selected_file)
			flash("Copied file: " .. selected_file)
			return
		end
		flash("No item selected to copy")
	end, {
		desc = "copy to clipboard",
		key = { "Y" },
		scope = "revisions.details",
	})
end

return M
