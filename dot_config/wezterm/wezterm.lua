local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()

local cmdpicker = wezterm.plugin.require 'https://github.com/abidibo/wezterm-cmdpicker'
local nordic, _ = wezterm.color.load_scheme(wezterm.config_dir .. '/colors/nordic.toml')

config.color_schemes = {
  nordic = nordic,
}
config.color_scheme = 'nordic'

config.font = wezterm.font_with_fallback {
  {
    family = 'JetBrainsMono Nerd Font',
    harfbuzz_features = {
      'calt=1',
      'clig=1',
      'liga=1',
    },
  },
}

config.font_size = 14.0
config.line_height = 1.05

-- Slight transparency
config.window_background_opacity = 0.92
config.macos_window_background_blur = 20

-- Neovim-friendly
config.term = 'xterm-256color'
config.enable_kitty_keyboard = true
config.enable_csi_u_key_encoding = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.scrollback_lines = 10000
config.adjust_window_size_when_changing_font_size = false

-- Leader key
config.leader = { key = 'w', mods = 'CTRL|SHIFT', timeout_milliseconds = 3000 }

config.keys = {
  { key = 'Enter', mods = 'ALT', action = act.ToggleFullScreen },
  -- Pane navigation that plays nicely with neovim/tmux
  { key = 'h', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Right' },

  -- Splits
  { key = '\\', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- Tabs
  { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },

  -- Opencode
  {
    key = 'O',
    mods = 'LEADER',
    action = wezterm.action_callback(function(window, pane)
      local right = pane:split {
        direction = 'Right',
        size = 0.25,
      }

      local top = right:split {
        direction = 'Top',
        size = 0.5,
        args = { '/bin/zsh', '-i' },
      }

      top:send_text 'opencode --port\n'
    end),
  },
}

cmdpicker.apply_to_config(config, {
  key = ' ',
  mods = 'LEADER',
  title = 'Command Palette',
  include_defaults = true,
  fuzzy = true,
})

return config
