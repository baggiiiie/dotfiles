local M = {}

local function trim(s)
	return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalize(path)
	if not path or path == "" then
		return nil, "No file selected"
	end
	if path:sub(1, 2) == "~/" then
		local home = os.getenv("HOME")
		if home and home ~= "" then
			path = home .. path:sub(2)
		end
	end
	path = path:gsub("//+", "/")
	return path
end

local function repo_root()
	local output, err = jj("root")
	local root = trim(output)
	if err or root == "" then
		return nil, err or "Failed to resolve jj repo root"
	end
	return root
end

function M.repo_relative(path)
	path = normalize(path)
	if not path then
		return nil, "No file selected"
	end

	if path:sub(1, 1) ~= "/" then
		if path == "." or path:match("^%.%.[/\\]") then
			return nil, string.format("Invalid repo-relative path: %s", path)
		end
		return path
	end

	local root, err = repo_root()
	if not root then
		return nil, err
	end

	if path == root then
		return nil, string.format("Path %q refers to the repo root, not a file", path)
	end

	local prefix = root .. "/"
	if path:sub(1, #prefix) == prefix then
		return path:sub(#prefix + 1)
	end

	return nil, string.format("Path %q is not inside repo %q", path, root)
end

function M.absolute(path)
	path = normalize(path)
	if not path then
		return nil, "No file selected"
	end

	if path:sub(1, 1) == "/" then
		return path
	end

	local root, err = repo_root()
	if not root then
		return nil, err
	end

	return root .. "/" .. path
end

function M.shell_quote(path)
	return string.format("%q", path)
end

return M
