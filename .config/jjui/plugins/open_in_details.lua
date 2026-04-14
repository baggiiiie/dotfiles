local path_utils = require("plugins.path_utils")

local M = {}
function M.setup(config)
	config.action("open in vim", function()
		local file = context.file()
		if not file then
			flash({ text = "No file selected", error = true })
			return
		end

		local repo_file, repo_err = path_utils.repo_relative(file)
		if not repo_file then
			flash({ text = repo_err, error = true })
			return
		end

		local open_file, open_err = path_utils.absolute(file)
		if not open_file then
			flash({ text = open_err, error = true })
			return
		end

		local change_id = context.change_id()
		local line = nil
		if change_id then
			local output, err = jj("diff", "-r", change_id, "--git", repo_file, "--no-pager")
			if not err and output then
				line = output:match("@@ %S+ %+(%d+)")
			end
		end
		if line then
			exec_shell("nvim +" .. line .. " " .. path_utils.shell_quote(open_file))
		else
			exec_shell("nvim " .. path_utils.shell_quote(open_file))
		end
	end, {
		desc = "open in vim",
		key = { "O" },
		scope = "revisions.details",
	})
end

return M
