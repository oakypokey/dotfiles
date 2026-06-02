local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

local kanagawa = wezterm.plugin.require("https://github.com/sravioli/kanagawa.wz")
local cmdpicker = wezterm.pligin.require("https://github.com/abidibo/wezterm-cmdpicker")

kanagawa.apply_to_config(config, {
	scheme = "wave"
})

config.font = wezterm.font_with_fallback({
	{
		family = "JetBrainsMono Nerd Font",
		harfbuzz_features = {
			"calt=1",
			"clig=1",
			"liga=1"
		},
	},
})

config.font_size = 14.0
config.line_height = 1.05


-- Slight transparency
config.window_background_opacity = 0.92
config.macos_window_background_blur = 20

-- Neovim-friendly
config.term = "xterm-256color"
config.enable_kitty_keyboard = true
config.enable_csi_u_key_encoding = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.scrollback_lines = 10000
config.adjust_window_size_when_changing_font_size = false


-- Leader key
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
	{ key = "Enter", mods = "ALT", action = act.ToggleFullScreen },
	-- Pane navigation that plays nicely with neovim/tmux
	{ key = "h", mods = "ALT", action = act.ToggleFullScreen },
	{ key = "j", mods = "ALT", action = act.ToggleFullScreen },
	{ key = "k", mods = "ALT", action = act.ToggleFullScreen },
	{ key = "l", mods = "ALT", action = act.ToggleFullScreen },
	{ key = "z", mods = "ALT", action = act.ToggleFullScreen },

	-- Splits
	{ key = "\\", mods = "ALT", action = act.ToggleFullScreen },
	{ key = "-", mods = "ALT", action = act.ToggleFullScreen },

	-- Tabs
	{ key = "c", mods = "ALT", action = act.ToggleFullScreen },
	{ key = "x", mods = "ALT", action = act.ToggleFullScreen },

}
