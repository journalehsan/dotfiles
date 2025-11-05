#!/usr/bin/env bash

# Dotfiles installer script
# This script sets up symbolic links for your dotfiles configuration
# - Links config directories to ~/.config/ (gtk, qt, fontconfig, etc.)
# - Links themes to ~/.themes/
# - Links icon themes to ~/.local/share/icons/
# - Links scripts from ~/dotfiles/scripts to ~/.local/bin/

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}=== Dotfiles Installation Script ===${NC}"
echo -e "${BLUE}Dotfiles directory: ${DOTFILES_DIR}${NC}"
echo

# Function to create symbolic link
create_symlink() {
    local source="$1"
    local target="$2"
    
    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$target")"
    
    # Remove existing file/directory if it exists
    if [[ -e "$target" || -L "$target" ]]; then
        echo -e "${YELLOW}Removing existing $target${NC}"
        rm -rf "$target"
    fi
    
    # Create symbolic link
    echo -e "${GREEN}Creating symlink: $target -> $source${NC}"
    ln -sf "$source" "$target"
}

# === STEP 1: Link Configuration Directories ===
echo -e "${BLUE}[1/3] Linking configuration directories...${NC}"

# Configuration directories to link
configs=(
    "omarchy"
    "waybar"
    "hypr"
    "fish"
    "nvim"
    "walker"
    "swayosd"
    "mako"
    "nwg-dock-hyprland"
    "nwg-drawer"
    "gtk-3.0"
    "gtk-4.0"
    "fontconfig"
    "qt5ct"
    "qt6ct"
    "QtProject"
)

# Create symbolic links for each config
for config in "${configs[@]}"; do
    source_path="$DOTFILES_DIR/.config/$config"
    target_path="$HOME/.config/$config"
    
    if [[ -d "$source_path" ]]; then
        create_symlink "$source_path" "$target_path"
    else
        echo -e "${RED}Warning: $source_path does not exist, skipping...${NC}"
    fi
done

# Link individual config files
config_files=(
    "QtProject.conf"
)

for config_file in "${config_files[@]}"; do
    source_path="$DOTFILES_DIR/.config/$config_file"
    target_path="$HOME/.config/$config_file"
    
    if [[ -f "$source_path" ]]; then
        create_symlink "$source_path" "$target_path"
    else
        echo -e "${RED}Warning: $source_path does not exist, skipping...${NC}"
    fi
done

echo

# === STEP 2: Link Themes and Icons ===
echo -e "${BLUE}[2/3] Linking themes and icons...${NC}"

# Create ~/.themes directory if it doesn't exist
mkdir -p "$HOME/.themes"

# Link themes from dotfiles/.themes to ~/.themes
if [[ -d "$DOTFILES_DIR/.themes" ]]; then
    theme_count=0
    for theme_dir in "$DOTFILES_DIR/.themes"/*; do
        if [[ -d "$theme_dir" ]]; then
            theme_name=$(basename "$theme_dir")
            create_symlink "$theme_dir" "$HOME/.themes/$theme_name"
            ((++theme_count))
        fi
    done
    if [[ $theme_count -gt 0 ]]; then
        echo -e "${GREEN}Linked $theme_count theme(s)${NC}"
    fi
else
    echo -e "${YELLOW}No themes found to link${NC}"
fi

# Create ~/.local/share directory if it doesn't exist
mkdir -p "$HOME/.local/share"

# Link icons directory
icon_source="$DOTFILES_DIR/.local/share/icons"
if [[ -d "$icon_source" ]]; then
    create_symlink "$icon_source" "$HOME/.local/share/icons"
    echo -e "${GREEN}Linked icon themes${NC}"
else
    echo -e "${YELLOW}No icons found to link${NC}"
fi

echo

# === STEP 3: Link Scripts to ~/.local/bin ===
echo -e "${BLUE}[3/3] Linking scripts to ~/.local/bin...${NC}"

# Create ~/.local/bin if it doesn't exist
mkdir -p "$HOME/.local/bin"

# Check if scripts directory exists
if [[ -d "$DOTFILES_DIR/scripts" ]]; then
    # Remove existing symbolic links in ~/.local/bin that point to dotfiles/scripts
    echo -e "${YELLOW}Removing existing script links...${NC}"
    for link in "$HOME/.local/bin"/*; do
        if [[ -L "$link" ]] && readlink "$link" | grep -q '/dotfiles/scripts/'; then
            rm "$link"
            echo -e "${YELLOW}Removed: $(basename "$link")${NC}"
        fi
    done
    
    # Create symbolic links for each script
    script_count=0
    for script in "$DOTFILES_DIR/scripts"/*; do
        if [[ -f "$script" || -L "$script" ]]; then
            script_name=$(basename "$script")
            link_path="$HOME/.local/bin/$script_name"
            
            # Create the symbolic link
            ln -sf "$script" "$link_path"
            echo -e "${GREEN}Linked: $script_name${NC}"
            ((++script_count))
        fi
    done
    
    if [[ $script_count -eq 0 ]]; then
        echo -e "${YELLOW}No scripts found in $DOTFILES_DIR/scripts${NC}"
    else
        echo -e "${GREEN}Linked $script_count script(s)${NC}"
    fi
else
    echo -e "${YELLOW}Warning: $DOTFILES_DIR/scripts does not exist, skipping script linking...${NC}"
fi

echo
echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo
echo -e "${BLUE}Summary:${NC}"
echo -e "  ✓ Configuration directories linked to ~/.config/"
echo -e "  ✓ Themes linked to ~/.themes/"
echo -e "  ✓ Icon themes linked to ~/.local/share/icons/"
echo -e "  ✓ Scripts linked to ~/.local/bin/"
echo
echo -e "${BLUE}Your dotfiles are now linked and will sync across devices!${NC}"
echo -e "${YELLOW}Don't forget to run: ${NC}"
echo -e "  ${GREEN}git add .${NC}"
echo -e "  ${GREEN}git commit -m \"Update configs\"${NC}"
echo -e "  ${GREEN}git push${NC}"
