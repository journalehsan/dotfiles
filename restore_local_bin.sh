#!/bin/bash

# Script to restore symbolic links from ~/dotfiles/scripts to ~/.local/bin/
# This recreates the setup where scripts in ~/dotfiles/scripts are linked to ~/.local/bin/

set -e  # Exit on any error

echo "Restoring symbolic links from ~/dotfiles/scripts to ~/.local/bin/"

# Create ~/.local/bin if it doesn't exist
mkdir -p ~/.local/bin

# Check if ~/dotfiles/scripts exists
if [ ! -d ~/dotfiles/scripts ]; then
    echo "Error: ~/dotfiles/scripts directory does not exist!"
    echo "Please make sure your dotfiles are properly cloned to ~/dotfiles"
    exit 1
fi

# Remove existing symbolic links in ~/.local/bin that point to ~/dotfiles/scripts
echo "Removing existing symbolic links to ~/dotfiles/scripts..."
for link in ~/.local/bin/*; do
    if [ -L "$link" ] && [ -n "$(readlink "$link" | grep '/dotfiles/scripts/')" ]; then
        rm "$link"
        echo "Removed: $link"
    fi
done

# Create symbolic links for each script in ~/dotfiles/scripts
echo "Creating symbolic links..."
for script in ~/dotfiles/scripts/*; do
    if [ -f "$script" ] || [ -L "$script" ]; then
        script_name=$(basename "$script")
        link_path="$HOME/.local/bin/$script_name"
        
        # Skip if it's already a symbolic link to the correct location
        if [ -L "$link_path" ] && [ "$(readlink "$link_path")" = "/home/ehsator/dotfiles/scripts/$script_name" ]; then
            echo "Already linked: $script_name"
        else
            # Create the symbolic link
            ln -sf "$HOME/dotfiles/scripts/$script_name" "$link_path"
            echo "Linked: $script_name -> ~/dotfiles/scripts/$script_name"
        fi
    fi
done

echo
echo "Restoration complete!"
echo "All scripts in ~/dotfiles/scripts are now linked to ~/.local/bin/"
echo
echo "Verify the setup with: ls -la ~/.local/bin/ | grep -E '^l'"