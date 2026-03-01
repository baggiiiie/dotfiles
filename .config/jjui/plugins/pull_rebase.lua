local M = {}

function M.setup(config)
	config.action("pull_rebase", function()
		pull_rebase()
	end, {
		desc = "pull and rebase",
		seq = { "w", "r" },
		scope = "revisions",
	})
end

local function trim(s)
	return (s or ""):match("^%s*(.-)%s*$")
end

local function detect_remote(bookmark_name)
	local key = "branch." .. bookmark_name .. ".remote"
	local out, err = jj_background("util", "exec", "--", "git", "config", "--get", key)
	local remote = trim(out)
	if err then
		remote = ""
	end

	if remote ~= "" then
		return remote
	end

	local _, upstream_err = jj_background("util", "exec", "--", "git", "remote", "get-url", "upstream")
	if not upstream_err then
		return "upstream"
	end
	return "origin"
end

local function get_local_bookmark_commit(bookmark)
	local template = 'if(self.present() && !remote, normal_target.commit_id().shortest(8) ++ "\\n", "")'
	local output = jj_background("bookmark", "list", bookmark, "-T", template)
	for line in output:gmatch("[^\n]+") do
		if line ~= "" then
			return line
		end
	end
	return nil
end

function pull_rebase()
	local bookmark_name = input({ title = "Bookmark to fetch", value = "main" })
	if not bookmark_name or bookmark_name == "" then
		return
	end

	local do_rebase = bookmark_name == "main"
	local remote = detect_remote(bookmark_name)

	flash("Auto-detected fetch remote: " .. remote)

	local _, track_err = jj_background("bookmark", "track", bookmark_name, "--remote=" .. remote)
	if track_err then
		flash({ text = "failed to track remote branch '" .. bookmark_name .. "' from remote '" .. remote .. "'", error = true })
		revisions.refresh()
		return
	end

	flash("1. get current bookmark info")
	local local_bookmark_commit_id = get_local_bookmark_commit(bookmark_name)
	if not local_bookmark_commit_id then
		flash({ text = "no local bookmark " .. bookmark_name .. " is tracking remote", error = true })
		revisions.refresh()
		return
	end

	flash("2. fetch remote branch '" .. bookmark_name .. "'")
	local _, fetch_err = jj_background("git", "fetch", "--branch", bookmark_name, "--remote", remote)
	if fetch_err then
		flash("no remote branch to fetch: " .. bookmark_name .. "@" .. remote)
		revisions.refresh()
		return
	end

	local remote_bookmark_commit_id = get_local_bookmark_commit(bookmark_name)
	if not remote_bookmark_commit_id then
		flash({ text = "remote bookmark does not exist for branch " .. bookmark_name .. ", probably untracked", error = true })
		revisions.refresh()
		return
	end

	if do_rebase then
		local rebase_revset =
			"children(" .. local_bookmark_commit_id .. ")::~.." .. remote_bookmark_commit_id .. "&mine()"

		local change_ids_output =
			jj_background("log", "-r", rebase_revset, "-T", 'change_id++"\\n"', "--no-graph", "--color", "never")
		local empty_before_output = jj_background(
			"log",
			"-r",
			rebase_revset,
			"-T",
			'if(empty, change_id++"\\n", "")',
			"--no-graph",
			"--color",
			"never"
		)

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

		flash(
			"3. rebase children of change id '" .. local_bookmark_commit_id .. "' onto fetched branch '" .. bookmark_name .. "'"
		)
		local _, rebase_err = jj_background(
			"rebase",
			"-r",
			rebase_revset,
			"--onto",
			"'" .. remote_bookmark_commit_id .. "'",
			"--ignore-immutable"
		)
		if rebase_err then
			flash({ text = "Rebase failed: " .. rebase_err, error = true })
			revisions.refresh()
			return
		end

		if #change_ids > 0 then
			local newly_empty = {}
			for _, cid in ipairs(change_ids) do
				if not empty_before[cid] then
					local empty_check = jj_background(
						"log",
						"-r",
						cid,
						"-T",
						'if(empty, "empty", "")',
						"--no-graph",
						"--color",
						"never"
					)
					if empty_check:find("empty") then
						table.insert(newly_empty, cid)
					end
				end
			end

			if #newly_empty > 0 then
				flash("4. abandon commits that became empty after rebase")
				for _, cid in ipairs(newly_empty) do
					jj_background("abandon", cid)
				end
			end
		end
	else
		flash("3. skipping rebase (use --rebase to enable)")
	end

	revisions.refresh()
end

return M
