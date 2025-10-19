# My Dotfiles 🏠

Personal configuration files for my Arch Linux setup with Hyprland, managed through symbolic links.

## What's Included

- **Hyprland** (`~/.config/hypr/`) - Wayland compositor configuration
- **Waybar** (`~/.config/waybar/`) - Status bar configuration
- **Fish Shell** (`~/.config/fish/`) - Shell configuration and functions
- **Neovim** (`~/.config/nvim/`) - Text editor configuration
- **Walker** (`~/.config/walker/`) - Application launcher
- **Omarchy** (`~/.config/omarchy/`) - Custom configuration

## Installation

### Fresh Install

1. **Clone the repository:**
   ```bash
   git clone https://github.com/journalehsan/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. **Run the install script:**
   ```bash
   ./install.sh
   ```

The script will:
- Create symbolic links from `~/.config/` to the dotfiles directory
- Back up any existing configurations
- Set up all configurations automatically

### Manual Installation

If you prefer to set up links manually:

```bash
ln -sf ~/dotfiles/.config/hypr ~/.config/hypr
ln -sf ~/dotfiles/.config/waybar ~/.config/waybar
ln -sf ~/dotfiles/.config/fish ~/.config/fish
ln -sf ~/dotfiles/.config/nvim ~/.config/nvim
ln -sf ~/dotfiles/.config/walker ~/.config/walker
ln -sf ~/dotfiles/.config/omarchy ~/.config/omarchy
```

## Usage

Since these are symbolic links, any changes you make to your configurations will automatically be reflected in the dotfiles repository. To sync changes:

```bash
cd ~/dotfiles
git add .
git commit -m "Update configurations"
git push
```

## Dependencies

Make sure you have these programs installed:
- Hyprland
- Waybar
- Fish shell
- Neovim
- Walker
- Git

## Structure

```
dotfiles/
├── .config/
│   ├── hypr/
│   ├── waybar/
│   ├── fish/
│   ├── nvim/
│   ├── walker/
│   └── omarchy/
├── install.sh
└── README.md
```

## License

Personal configurations - feel free to use and modify as needed!