# Agent Instructions for dotfiles
Personal dotfiles (AstroNvim, Fish, Hyprland). No tests/builds.

## Code Style

### Lua (Neovim)
- 2-space indent, 120 char line width, prefer double quotes
- Use `---@type` annotations, Lazy specs: `{ "plugin_name", opts = {...} }`
- Deactivated files: `if true then return {} end` - REMOVE to activate

### Fish
- `function name --description "desc"`, `set -l` for locals, `set_color` for output
- Nerd Font icons (e.g., 󰊢, 󰘬)

### Shell
- Bash: `#!/bin/bash`, Python: `#!/usr/bin/env python3`
- Use `sudo` sparingly, add `2>/dev/null || true` for optional commands

## Linting
- Lua format: `stylua --config .config/nvim/.stylua.toml <file>`
- Lua lint: `selene --config .config/nvim/selene.toml <file>`

## Organization
- Neovim: `.config/nvim/lua/plugins/*.lua`, `lazy_setup.lua`
- Hyprland: `.config/hypr/*.conf` (binds.conf, monitors.conf, etc.)
- Fish: `.config/fish/functions/*.fish`