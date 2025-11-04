# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for an Arch Linux system with Hyprland (Wayland compositor). The repository uses symbolic links to manage configurations, with all settings tracked in Git and linked to their respective system locations.

## Installation & Setup

### Initial Setup
```bash
# Clone and install dotfiles
git clone https://github.com/journalehsan/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The `install.sh` script creates symbolic links for:
- Configuration directories from `.config/` → `~/.config/`
- Themes from `.themes/` → `~/.themes/`
- Icons from `.local/share/icons/` → `~/.local/share/icons/`
- Scripts from `scripts/` → `~/.local/bin/`

### Scripts Management
To restore or update script symlinks after adding new scripts:
```bash
~/dotfiles/restore_local_bin.sh
```

## Architecture

### Theme Management: Omarchy System
The repository uses **Omarchy** for unified theme management across all applications:

- **Base themes location**: `~/.local/share/omarchy/default/`
- **Custom themes**: `.config/omarchy/themes/dracula/`
- **Current theme symlink**: `.config/omarchy/current/theme/` → active theme
- **Theme files include**: `hyprland.conf`, `hyprlock.conf`, `neovim.lua`, `waybar.css`, `mako.ini`, `walker.css`, `swayosd.css`, `ghostty.conf`, `alacritty.toml`, `btop.theme`

When modifying themes, update files in `.config/omarchy/themes/<theme-name>/`, not in the system defaults.

### Hyprland Configuration
Hyprland loads config in this order (later files override earlier ones):
1. Omarchy defaults from `~/.local/share/omarchy/default/hypr/`
2. Current theme: `~/.config/omarchy/current/theme/hyprland.conf`
3. User overrides in `~/.config/hypr/`:
   - `monitors.conf` - Display configuration
   - `input.conf` - Keyboard, mouse, touchpad settings
   - `bindings.conf` - Custom keybindings and application launchers
   - `envs.conf` - Environment variables
   - `looknfeel.conf` - Visual customization
   - `autostart.conf` - Startup applications

Always edit user files in `~/.config/hypr/`, never the Omarchy defaults.

### Fish Shell Configuration
Fish configuration is split across:
- **Main config**: `.config/fish/config.fish` - Aliases, environment, prompt settings
- **Functions**: `.config/fish/functions/*.fish` - Custom shell functions
- **Important environment settings**:
  - Proxy functions: `set-proxy`, `unset-proxy`
  - Rust path switcher: `change_rust_path` (prioritizes `~/.cargo/bin`)
  - VPN management aliases: `vpn-start`, `vpn-stop`, `vpn-check`
  - Qt theme override: `QT_QPA_PLATFORMTHEME=qt5ct`

### Custom Scripts
Executable scripts in `scripts/` directory (symlinked to `~/.local/bin/`):
- `with-proxy` - Wrapper to run commands with proxy settings
- `nvim-proxy` - Launch Neovim with proxy
- `warp-proxy` - Launch Warp terminal with proxy
- `ram_monitor` - Python RAM usage monitor
- `disk_cleanup.sh` - Arch Linux disk cleanup utility
- `add_wallpaper` - Wallpaper management
- Waybar helper scripts in `.config/waybar/scripts/`:
  - `jalali-date.sh`, `jalali-toggle.sh`, `jalali-waybar.sh` - Persian calendar support
  - `network-speed.sh` - Network monitoring

## Common Development Tasks

### Managing Configuration Changes
Since configs are symlinked, any edits automatically reflect in the repo:
```bash
cd ~/dotfiles
git add .
git commit -m "Update configurations"
git push
```

### Adding New Application Config
1. Add config to `.config/<app-name>/` in dotfiles repo
2. Update `configs=()` array in `install.sh` if it's a directory
3. Run `./install.sh` to create symlink

### Adding New Scripts
1. Place script in `scripts/` directory
2. Make executable: `chmod +x scripts/<script-name>`
3. Run `~/dotfiles/restore_local_bin.sh` to create symlink
4. Script is now available system-wide

### Theme Modifications
To modify the Dracula theme:
```bash
cd ~/.config/omarchy/themes/dracula/
# Edit theme files for specific applications
# Changes propagate to all apps using that theme file
```

### Working with Neovim Configuration
The Neovim config uses LazyVim with Avante.nvim for AI assistance:
- Config location: Symlinked through Omarchy (check `~/.config/nvim/`)
- Theme: `.config/omarchy/themes/dracula/neovim.lua`
- Performance docs: `NEOVIM_AVANTE_PERFORMANCE_GUIDE.md`, `NEOVIM_PERFORMANCE_IMPLEMENTATION_SUMMARY.md`
- Quick start: `AVANTE_QUICK_START.md`

## Environment Considerations

### Proxy Setup
This system frequently uses proxy configuration:
- Proxy scripts are in `~/.local/bin/` (with-proxy, nvim-proxy, warp-proxy)
- Fish functions: `set-proxy` / `unset-proxy` for shell session
- Default proxy: `socks5://127.0.0.1:1080`
- VPN aliases configured in Fish config

### LDAP Authentication
The system includes LDAP settings (used for enterprise environments):
- Authentication: `samaccountname`-based
- No password sync: `LDAP_SYNC_PASSWORDS=false`
- Fallback disabled: `LDAP_LOGIN_FALLBACK=false`
- SSL validation: Testing mode (`LDAP_OPT_X_TLS_NEVER`)

### Display Server
This is a **Wayland-only** environment using Hyprland. X11-specific solutions will not work. Always consider:
- Use `uwsm app --` prefix for launching Wayland applications
- Use `--enable-wayland-ime` for IME support in Electron apps
- Check Wayland compatibility before suggesting tools

## Key Technologies

- **Display**: Hyprland (Wayland compositor)
- **Bar**: Waybar with custom scripts
- **Shell**: Fish 4.1.2 with Vi keybindings
- **Notifications**: Mako
- **Launcher**: Walker
- **Editor**: Neovim with LazyVim + Avante.nvim
- **Terminal**: WezTerm (preferred), Ghostty (configured)
- **Theme System**: Omarchy (unified theming)
- **Current Theme**: Dracula
- **Package Manager**: Paru (aliased as `yay`)
- **File Manager**: Nautilus (aliased to `cosmic-files`)
