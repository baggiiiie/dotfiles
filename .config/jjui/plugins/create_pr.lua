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
		local name, url = line:match("^(%S+)%s+(%S+)")
		if name then
			table.insert(remotes, { name = name, url = url })
		end
	end
	return remotes
end

local function parse_repo_from_url(url)
	local user, repo = url:match("git.*%.com[:/]([^/]+)/([^/.]+)")
	if user and repo then
		return user .. "/" .. repo, user
	end
	return nil, nil
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
		local remote_names = {}
		for _, r in ipairs(remotes) do
			table.insert(remote_names, r.name)
		end
		local picked = choose({
			options = remote_names,
			title = "Select remote",
			ordered = true,
		})
		if not picked then
			return
		end
		for _, r in ipairs(remotes) do
			if r.name == picked then
				selected_remote = r
				break
			end
		end
	end

	-- Parse user/repo from remote URL for -R flag
	local gh_repo, target_owner = parse_repo_from_url(selected_remote.url)
	if not gh_repo then
		flash("Could not parse user/repo from remote URL: " .. selected_remote.url)
		return
	end

	-- Find origin remote (the user's fork) to push to
	local origin
	for _, r in ipairs(remotes) do
		if r.name == "origin" then
			origin = r
			break
		end
	end
	origin = origin or selected_remote

	-- Push branch to origin
	jj("bookmark", "track", branch .. "@" .. origin.name)
	local _, push_err = jj("git", "push", "-b", branch)
	if push_err then
		flash("Push failed: " .. push_err)
		return
	end

	-- Prefix branch with fork owner when targeting a different owner's repo
	local _, origin_owner = parse_repo_from_url(origin.url)
	local gh_branch = branch
	if origin_owner and target_owner and origin_owner ~= target_owner then
		gh_branch = origin_owner .. ":" .. branch
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
	local r_flag = "-R " .. sq(gh_repo)
	local pr_url, pr_err = jj(
		"util",
		"exec",
		"--",
		"bash",
		"-c",
		"gh pr view "
			.. sq(gh_branch)
			.. " "
			.. r_flag
			.. " --json url -q .url 2>/dev/null || gh pr create -B main -H "
			.. sq(gh_branch)
			.. " "
			.. r_flag
			.. " -t "
			.. sq(title)
			.. " -b "
			.. sq(body)
	)

	revisions.refresh()
	if pr_err then
		flash("PR failed: " .. pr_err)
	else
		pr_url = pr_url:match("^%s*(.-)%s*$") or ""
		flash("Copied to clipboard PR URL: " .. pr_url)
		copy_to_clipboard(pr_url)
		jj("util", "exec", "--", "open", pr_url)
	end
end

return M
