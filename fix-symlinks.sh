#!/bin/bash
# Fix broken symlinks from old username ehsator to ehsantork

echo "Fixing broken symlinks from ehsator to ehsantork..."

# Find all symlinks pointing to /home/ehsator and update them
find /home/ehsantork/dotfiles -type l | while read -r link; do
    target=$(readlink "$link")
    if [[ "$target" == /home/ehsator/* ]]; then
        new_target="${target/\/home\/ehsator/\/home\/ehsantork}"
        echo "Updating: $link"
        echo "  Old target: $target"
        echo "  New target: $new_target"
        ln -sf "$new_target" "$link"
    fi
done

echo "Done! All symlinks have been updated."
