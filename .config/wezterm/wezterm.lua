local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Dracula color scheme
config.color_scheme = 'Dracula'

-- Font configuration
config.font = wezterm.font('JetBrains Mono')
config.font_size = 11.0

-- Window appearance
config.window_padding = {
  left = 2,
  right = 2,
  top = 0,
  bottom = 0,
}

-- Tab bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false

return config
