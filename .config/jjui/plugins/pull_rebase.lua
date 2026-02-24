local M = {}

function M.setup(config)
	config.action("pull_rebase", function()
		pull_rebase()
	end, {
		desc = "fetch remote and rebase local changes",
		key = { "ctrl+u" },
		scope = "revisions",
	})
end

local function get_remotes()
	local output = jj_background("git", "remote", "list")
	local remotes = {}
	for line in output:gmatch("[^\n]+") do
		local name = line:match("^(%S+)")
		if name then
			table.insert(remotes, name)
		end
	end
	return remotes
end

local function get_local_bookmark_commit(bookmark)
	local template = 'if(self.present() && !remote, normal_target.commit_id().shortest(12) ++ "\n", "")'
	local output = jj_background("bookmark", "list", bookmark, "-T", template)
	for line in output:gmatch("[^\n]+") do
		if line ~= "" then
			return line
		end
	end
	return nil
end

function pull_rebase()
	-- Pre-fetch remotes before blocking on user input
	local remotes = get_remotes()
	local remote

	-- Pick bookmark to fetch
	local bookmark_name = input({ title = "Bookmark to fetch", value = "main" })
	if not bookmark_name or bookmark_name == "" then
		return
	end
	if #remotes == 0 then
		flash("No git remotes found")
		return
	elseif #remotes == 1 then
		remote = remotes[1]
	else
		remote = choose({
			options = remotes,
			title = "Select remote to fetch from",
			ordered = true,
		})
		if not remote then
			return
		end
	end

	-- Track and fetch immediately — this is the slowest part (network)
	flash("Fetching " .. bookmark_name .. " from " .. remote .. "...")
	jj_async("bookmark", "track", bookmark_name, "--remote=" .. remote)
	local _, fetch_err = jj_background("git", "fetch", "--branch", bookmark_name, "--remote", remote)
	if fetch_err then
		flash("Fetch failed: " .. fetch_err)
		return
	end

	-- Get bookmark commit after fetch
	local commit_id = get_local_bookmark_commit(bookmark_name)
	if not commit_id then
		flash("No local bookmark '" .. bookmark_name .. "' found")
		return
	end

	-- Find revisions to rebase: my commits that are ancestors of @ but not ancestors of the bookmark
	local rebase_revset = "mine() & ancestors(@) & ~ancestors(" .. commit_id .. ") & ~" .. commit_id

	-- Ask whether to rebase (for non-main bookmarks)
	if bookmark_name ~= "main" then
		local action = choose({
			options = { "Yes, rebase", "No, just fetch" },
			title = "Rebase local changes onto fetched " .. bookmark_name .. "?",
			ordered = true,
		})
		if not action then
			revisions.refresh()
			return
		end
		if not action:find("Yes") then
			flash("Fetched " .. bookmark_name .. " from " .. remote)
			revisions.refresh()
			return
		end
	end

	flash("Collecting revisions to rebase...")
	-- Get change IDs before rebase to check for newly empty commits
	local change_ids_output = jj_background("log", "-r", rebase_revset, "-T", 'change_id++"\\n"', "--no-graph", "--color", "never")
	local empty_before_output =
		jj_background("log", "-r", rebase_revset, "-T", 'if(empty, change_id++"\\n", "")', "--no-graph", "--color", "never")

	local change_ids = {}
	for line in change_ids_output:gmatch("[^\n]+") do
		if line ~= "" then
			table.insert(change_ids, line)
		end
	end

	local empty_before = {}
	for line in empty_before_output:gmatch("[^\n]+") do
		if line ~= "" then
			empty_before[line] = true
		end
	end

	if #change_ids == 0 then
		flash("Fetched " .. bookmark_name .. " (nothing to rebase)")
		revisions.refresh()
		return
	end

	flash("Rebasing " .. #change_ids .. " revision(s) onto " .. bookmark_name .. "...")
	local _, rebase_err = jj_background("rebase", "-r", rebase_revset, "--onto", "'" .. commit_id .. "'", "--ignore-immutable")
	if rebase_err then
		flash("Rebase failed: " .. rebase_err)
		revisions.refresh()
		return
	end

	-- Abandon commits that became empty after rebase
	flash("Checking for empty commits...")
	local abandoned = 0
	for _, cid in ipairs(change_ids) do
		if not empty_before[cid] then
			local empty_check = jj_background("log", "-r", cid, "-T", 'if(empty, "empty", "")', "--no-graph", "--color", "never")
			if empty_check:find("empty") then
				jj_background("abandon", cid)
				abandoned = abandoned + 1
			end
		end
	end

	revisions.refresh()

	local msg = "Rebased " .. #change_ids .. " revision(s) onto " .. bookmark_name
	if abandoned > 0 then
		msg = msg .. ", abandoned " .. abandoned .. " empty"
	end
	flash(msg)
end

return M
