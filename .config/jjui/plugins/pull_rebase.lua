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

local function get_local_bookmark_commit(bookmark)
	local template = 'if(self.present() && !remote, normal_target.commit_id().shortest(12) ++ "\n", "")'
	local output = jj("bookmark", "list", bookmark, "-T", template)
	for line in output:gmatch("[^\n]+") do
		if line ~= "" then
			return line
		end
	end
	return nil
end

function pull_rebase()
	-- Pick bookmark to fetch
	local bookmark_name = input({ title = "Bookmark to fetch", value = "main" })
	if not bookmark_name or bookmark_name == "" then
		return
	end

	-- Pick remote
	local remotes = get_remotes()
	local remote
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

	-- Track the bookmark
	jj("bookmark", "track", bookmark_name .. "@" .. remote)

	-- 1. Get current local bookmark commit ID before fetch
	local old_commit_id = get_local_bookmark_commit(bookmark_name)
	if not old_commit_id then
		flash("No local bookmark '" .. bookmark_name .. "' tracking remote")
		return
	end

	-- 2. Fetch remote branch
	flash("Fetching " .. bookmark_name .. " from " .. remote .. "...")
	local _, fetch_err = jj("git", "fetch", "--branch", bookmark_name, "--remote", remote)
	if fetch_err then
		flash("Fetch failed: " .. fetch_err)
		return
	end

	-- 3. Get new commit ID after fetch
	local new_commit_id = get_local_bookmark_commit(bookmark_name)
	if not new_commit_id then
		flash("Bookmark disappeared after fetch")
		return
	end

	if old_commit_id == new_commit_id then
		flash("Already up to date")
		revisions.refresh()
		return
	end

	-- Ask whether to rebase
	local do_rebase = true
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
		do_rebase = action:find("Yes") ~= nil
	end

	if not do_rebase then
		flash("Fetched " .. bookmark_name .. " from " .. remote)
		revisions.refresh()
		return
	end

	-- 4. Rebase children of old commit onto new commit
	local rebase_revset = "children(" .. old_commit_id .. ")::~.." .. new_commit_id .. "&mine()"

	-- Get change IDs before rebase to check for newly empty commits
	local change_ids_output = jj("log", "-r", rebase_revset, "-T", 'change_id++"\\n"', "--no-graph", "--color", "never")
	local empty_before_output =
		jj("log", "-r", rebase_revset, "-T", 'if(empty, change_id++"\\n", "")', "--no-graph", "--color", "never")

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

	local _, rebase_err = jj("rebase", "-r", rebase_revset, "--onto", "'" .. new_commit_id .. "'", "--ignore-immutable")
	if rebase_err then
		flash("Rebase failed: " .. rebase_err)
		revisions.refresh()
		return
	end

	-- 5. Abandon commits that became empty after rebase
	local abandoned = 0
	for _, cid in ipairs(change_ids) do
		if not empty_before[cid] then
			local empty_check = jj("log", "-r", cid, "-T", 'if(empty, "empty", "")', "--no-graph", "--color", "never")
			if empty_check:find("empty") then
				jj("abandon", cid)
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
