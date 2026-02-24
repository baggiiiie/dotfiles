local bookmark = require("plugins.bookmark")
local bookmark2 = require("plugins.bookmark2")
local bookmark_view = require("plugins.bookmark_view")
local commit = require("plugins.commit")
local copy = require("plugins.copy")
local vim = require("plugins.open_in_details")
local create_pr = require("plugins.create_pr")
local pull_rebase = require("plugins.pull_rebase")

function setup(config)
	bookmark.setup(config)
	bookmark2.setup(config)
	bookmark_view.setup(config)
	commit.setup(config)
	copy.setup(config)
	vim.setup(config)
	create_pr.setup(config)
	pull_rebase.setup(config)
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

		local diff = jj("diff", "--git", "-r", context.change_id(), context.file())
		local line_number = first_hunk_new_lineno(diff)
		exec_shell(string.format("nvim +%q %q", line_number, context.file()))
	end, {
		scope = "revisions.details",
		key = { "x" },
	})
end
