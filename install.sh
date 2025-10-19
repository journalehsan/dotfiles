#!/usr/bin/env bash

# Dotfiles installer script
# This script sets up symbolic links for your dotfiles configuration

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

# Configuration directories to link
configs=(
    "omarchy"
    "waybar"
    "hypr"
    "fish"
    "nvim"
    "walker"
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

echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo -e "${BLUE}Your dotfiles are now linked. Any changes to your configs will be automatically tracked in the dotfiles repository.${NC}"
echo -e "${BLUE}Don't forget to run 'git add . && git commit -m \"Update configs\" && git push' to sync your changes!${NC}"