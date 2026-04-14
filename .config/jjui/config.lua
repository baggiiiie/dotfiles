local bookmark = require("plugins.bookmark")
local bookmark_view = require("plugins.bookmark_view")
local commit = require("plugins.commit")
local copy = require("plugins.copy")
local vim = require("plugins.open_in_details")
local create_pr = require("plugins.create_pr")
local pull_rebase = require("plugins.pull_rebase")
local path_utils = require("plugins.path_utils")

function setup(config)
	bookmark.setup(config)
	bookmark_view.setup(config)
	commit.setup(config)
	copy.setup(config)
	vim.setup(config)
	create_pr.setup(config)
	pull_rebase.setup(config)
	config.action("diff from main", function()
		jj_interactive(
			"util",
			"exec",
			"--",
			"bash",
			"-c",
			"/Users/ydai/repos/personal/dotfiles/.config/jj/jj-diffnav.sh -f main -t " .. context.change_id()
		)
	end, {
		scope = "revisions",
		seq = { "w", "d" },
	})
	config.action("edit file", function()
		local function first_hunk_new_lineno(git_diff)
			for line in git_diff:gmatch("[^\n]+") do
				if line:sub(1, 3) == "@@ " then
					local new_start = line:match("%+(%d+)")
					if new_start then
						return tonumber(new_start)
					end
				end
			end
			return nil
		end

		local file = context.file()
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

		local diff = jj("diff", "--git", "-r", context.change_id(), repo_file)
		local line_number = first_hunk_new_lineno(diff)
		if line_number then
			exec_shell(string.format("nvim +%d %s", line_number, path_utils.shell_quote(open_file)))
		else
			exec_shell(string.format("nvim %s", path_utils.shell_quote(open_file)))
		end
	end, {
		scope = "revisions.details",
		key = { "x" },
	})
end
