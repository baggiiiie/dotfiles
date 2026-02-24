local bookmark = require("plugins.bookmark")
local bookmark2 = require("plugins.bookmark2")
local commit = require("plugins.commit")
local copy = require("plugins.copy")
local vim = require("plugins.open_in_details")
local create_pr = require("plugins.create_pr")
local pull_rebase = require("plugins.pull_rebase")

function setup(config)
	config.action("say hello to me", function()
		flash("hello from config.lua")
	end, {
		desc = "hello to me",
		seq = { "w", "p" },
		scope = "revisions",
	})
	bookmark.setup(config)
	bookmark2.setup(config)
	commit.setup(config)
	copy.setup(config)
	vim.setup(config)
	create_pr.setup(config)
	pull_rebase.setup(config)
end
