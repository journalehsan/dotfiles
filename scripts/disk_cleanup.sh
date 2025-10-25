#!/bin/bash

# Disk cleanup script for Arch Linux
# This script safely cleans various cache and temporary files

echo "Starting disk cleanup..."

# Clean pacman cache (keep current packages, remove old ones)
echo "Cleaning pacman cache..."
sudo pacman -Sc --noconfirm

# Clean package build cache (if using makepkg or AUR helpers)
echo "Cleaning package build cache..."
rm -rf ~/.cache/paru/
rm -rf ~/.cache/yay/
rm -rf ~/builds/ 2>/dev/null || true

# Clean user cache directory
echo "Cleaning user cache..."
rm -rf ~/.cache/mesa_shader_cache/ 2>/dev/null || true
rm -rf ~/.cache/fontconfig/ 2>/dev/null || true
find ~/.cache -name "*.cache" -type f -delete 2>/dev/null || true

# Clean temporary files
echo "Cleaning temporary files..."
find /tmp -type f -atime +7 -delete 2>/dev/null || true

# Clean thumbnails cache
echo "Cleaning thumbnails cache..."
rm -rf ~/.cache/thumbnails/large/ 2>/dev/null || true
rm -rf ~/.cache/thumbnails/normal/ 2>/dev/null || true

# Clean pip cache (if Python packages were installed with pip)
echo "Cleaning pip cache..."
pip cache purge 2>/dev/null || true
pip3 cache purge 2>/dev/null || true

# Clean npm cache (if node packages exist)
echo "Cleaning npm cache..."
npm cache clean --force 2>/dev/null || true

# Clean cargo cache (Rust packages)
echo "Cleaning cargo cache..."
cargo cache --autoclean 2>/dev/null || true

# Clean system journal logs (keep recent logs, remove old ones)
echo "Cleaning system journal logs..."
sudo journalctl --vacuum-time=7d

# Clean thumbnails older than 30 days
find ~/.cache/thumbnails -type f -atime +30 -delete 2>/dev/null || true

# Clean browser caches if they exist
echo "Cleaning browser caches..."
rm -rf ~/.cache/google-chrome/* 2>/dev/null || true
rm -rf ~/.cache/chromium/* 2>/dev/null || true
rm -rf ~/.cache/mozilla/firefox/* 2>/dev/null || true
rm -rf ~/.cache/BraveSoftware/* 2>/dev/null || true
rm -rf ~/.cache/microsoft-edge/* 2>/dev/null || true
rm -rf ~/.cache/zen-browser/* 2>/dev/null || true

echo "Disk cleanup completed!"
df -h | grep -E '^/dev/' | head -1
df -h | grep -E '^/dev/' | awk '{print $1": "$4" free out of "$2" ("$5" used)"}'