local utils = require("plugins.bookmark_utils")
local M = {}

function M.setup(config)
	config.action("create_pr", function()
		create_pr()
	end, {
		desc = "create_pr",
		key = { "ctrl+p" },
		scope = "revisions",
	})
end

local function get_remotes()
	local output = jj("git", "remote", "list")
	local remotes = {}
	for line in output:gmatch("[^\n]+") do
		local name = line:match("^(%S+)")
		if name then
			table.insert(remotes, name)
		end
	end
	return remotes
end

function create_pr()
	local change_id = context.change_id()
	if not change_id then
		flash("No revision selected")
		return
	end

	-- Get bookmarks on this revision
	local bookmarks = utils.get_bookmarks(change_id)

	local branch
	if #bookmarks == 0 then
		-- No bookmark: offer to create one or push with auto-generated name
		local action = choose({
			options = { "push and create bookmark (jj git push -c)", "create bookmark manually" },
			title = "No bookmark on revision",
			ordered = true,
		})
		if not action then
			return
		end

		if action:find("push and create") then
			local output, err = jj("git", "push", "-c", change_id)
			if err then
				flash("Push failed: " .. err)
				return
			end
			-- Re-fetch bookmarks after push created one
			bookmarks = utils.get_bookmarks(change_id)
			if #bookmarks == 0 then
				flash("Push succeeded but no bookmark found")
				return
			end
			branch = bookmarks[1]
		else
			local name = input({ title = "New bookmark name" })
			if not name or name == "" then
				return
			end
			jj("bookmark", "create", name, "-r", change_id)
			revisions.refresh()
			branch = name
		end
	elseif #bookmarks == 1 then
		branch = bookmarks[1]
	else
		branch = choose({
			options = bookmarks,
			title = "Multiple bookmarks — select one for PR",
			ordered = true,
		})
		if not branch then
			return
		end
	end

	-- Select remote if multiple
	local remotes = get_remotes()
	local selected_remote
	if #remotes == 0 then
		flash("No git remotes found")
		return
	elseif #remotes == 1 then
		selected_remote = remotes[1]
	else
		selected_remote = choose({
			options = remotes,
			title = "Select remote",
			ordered = true,
		})
		if not selected_remote then
			return
		end
	end

	-- Track and push the bookmark
	jj("bookmark", "track", branch .. "@" .. selected_remote)
	local _, push_err = jj("git", "push", "-b", branch)
	if push_err then
		flash("Push failed: " .. push_err)
		return
	end

	-- Get title/body from jj (--fill won't work because gh can't run git log in jj repos)
	local desc = jj("log", "-r", change_id, "-T", "description", "--no-graph")
	desc = desc:match("^%s*(.-)%s*$") or ""
	local title = desc:match("^([^\n]+)") or branch
	local body = desc:match("\n(.+)$") or ""

	-- Escape single quotes for shell
	local function sq(s)
		return "'" .. s:gsub("'", "'\\''") .. "'"
	end

	-- Use jj util exec so gh can access the underlying git repo
	jj_interactive(
		"util",
		"exec",
		"--",
		"bash",
		"-c",
		"gh pr view "
			.. branch
			.. " -w 2>/dev/null || gh pr create -B main -H "
			.. branch
			.. " -t "
			.. sq(title)
			.. " -b "
			.. sq(body)
			.. " -w"
	)

	revisions.refresh()
	flash("PR created")
end

return M
