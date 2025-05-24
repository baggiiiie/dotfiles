-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()
local act = wezterm.action

-- This is where you actually apply your config choices
-- config.font = wezterm.font("Fira Code", { weight = "Medium" })
-- config.harfbuzz_features = { "zero", "cv02", "cv04", "cv14", "onum", "cv30" }

config.default_prog = { "zsh" }

config.front_end = "WebGpu"
-- config.freetype_load_target = "Light"
-- config.freetype_render_target = "Normal"
-- config.font = wezterm.font("Berkeley Mono", { weight = "Regular" })
config.font = wezterm.font("JetBrains Mono", { weight = "Regular" })
-- config.font = wezterm.font("Monaspace Argon", { weight = "Medium" })
-- config.harfbuzz_features = { "ss01", "ss02", "ss03", "ss04", "ss05", "ss06", "ss07", "ss08", "calt", "dlig" }
-- For example, changing the color scheme:

--debug, run `WEZTERM_LOG=info wezterm` to see all key events
config.debug_key_events = true

config.initial_rows = 53
config.initial_cols = 160
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

-- For example, changing the color scheme:
config.color_scheme = "Catppuccin Macchiato"
config.window_background_opacity = 0.85
config.text_background_opacity = 0.75
config.macos_window_background_blur = 15
config.font_size = 19
config.line_height = 1.2
config.tab_max_width = 30
config.tab_bar_at_bottom = true
config.colors = {
	tab_bar = {
		active_tab = {
			bg_color = "#2b2042",
			fg_color = "#F8C8EB",
			italic = true,
		},
	},
}

config.inactive_pane_hsb = {
	-- hue = 0.9,
	saturation = 0.5,
	brightness = 0.3,
}

config.window_padding = {
	left = 20,
	right = 20,
	top = 20,
	bottom = 5,
}

config.keys = {
	-- split pane stuff
	{
		key = "v",
		mods = "ALT",
		action = wezterm.action.SplitPane({
			direction = "Left",
			size = { Percent = 25 },
		}),
	},
	{
		key = "s",
		mods = "ALT",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "LeftArrow",
		mods = "ALT",
		action = act.ActivatePaneDirection("Left"),
	},
	{
		key = "RightArrow",
		mods = "ALT",
		action = act.ActivatePaneDirection("Right"),
	},
	{
		key = "UpArrow",
		mods = "ALT",
		action = act.ActivatePaneDirection("Up"),
	},
	{
		key = "DownArrow",
		mods = "ALT",
		action = act.ActivatePaneDirection("Down"),
	},
	{
		key = "w",
		mods = "ALT",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
	-- tab bar stuff
	{
		key = "Tab",
		mods = "CTRL",
		action = wezterm.action.ActivateLastTab,
	},
	{ key = ",", mods = "ALT", action = act.ActivateTabRelative(-1) },
	{ key = ".", mods = "ALT", action = act.ActivateTabRelative(1) },
	-- copy mode to ctrl-v
	{ key = "c", mods = "ALT", action = wezterm.action.ActivateCopyMode },
	{ key = "UpArrow", mods = "SHIFT", action = act.ScrollByPage(-0.3) },
	{ key = "DownArrow", mods = "SHIFT", action = act.ScrollByPage(0.3) },
}

-- and finally, return the configuration to wezterm
return config
