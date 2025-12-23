local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.color_scheme = 'Dracula'
config.keys = {
  {key="Enter", mods="SHIFT", action=wezterm.action{SendString="\x1b\r"}},
}

return config
