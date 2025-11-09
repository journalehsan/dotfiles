#!/bin/bash
# Installation script for Celeron N4000 optimizations

set -e

echo "=== Installing required packages ==="
if ! pacman -Q ananicy-cpp &>/dev/null; then
    sudo pacman -S --needed ananicy-cpp
fi

if ! pacman -Q ananicy-cpp-rules &>/dev/null; then
    echo "Installing ananicy-cpp-rules from AUR (optional but recommended)"
    echo "Run: yay -S ananicy-cpp-rules"
fi

echo ""
echo "=== Applying sysctl optimizations ==="
sudo cp 99-celeron-optimizations.conf /etc/sysctl.d/
sudo sysctl --system
echo "✓ Sysctl parameters applied"

echo ""
echo "=== Setting up ananicy-cpp rules ==="
sudo mkdir -p /etc/ananicy.d
sudo cp ananicy-hyprland-rules.rules /etc/ananicy.d/00-hyprland.rules
sudo systemctl enable --now ananicy-cpp
echo "✓ Ananicy-cpp enabled and started"

echo ""
echo "=== Checking zram configuration ==="
if [ -f /etc/systemd/zram-generator.conf ]; then
    echo "Backing up existing zram config..."
    sudo cp /etc/systemd/zram-generator.conf /etc/systemd/zram-generator.conf.bak
fi
sudo cp zram-config.conf /etc/systemd/zram-generator.conf
echo "✓ Zram config updated (will apply on next boot or run: sudo systemctl restart systemd-zram-setup@zram0.service)"

echo ""
echo "=== BTRFS Mount Options ==="
echo "⚠ Manual step required: Edit /etc/fstab to add optimized mount options"
echo "See btrfs-mount-options.txt for recommended options"
echo "Current options: compress=zstd:3,ssd,space_cache=v2"
echo "Add: noatime,discard=async,commit=120"
echo ""
echo "Example command to edit fstab:"
echo "  sudo nano /etc/fstab"
echo ""

echo "=== Additional optimizations ==="
echo ""
echo "1. Enable fstrim timer for eMMC:"
echo "   sudo systemctl enable --now fstrim.timer"
echo ""
echo "2. Limit journal size (reduces eMMC writes):"
echo "   sudo journalctl --vacuum-size=50M"
echo "   echo 'SystemMaxUse=50M' | sudo tee -a /etc/systemd/journald.conf"
echo ""
echo "3. Disable unnecessary services:"
echo "   sudo systemctl disable bluetooth.service  # if not needed"
echo "   sudo systemctl disable cups.service       # if no printing"
echo ""
echo "4. For better browser performance, add to ~/.config/chromium-flags.conf or firefox about:config:"
echo "   Chromium: --disable-gpu-compositing --enable-features=VaapiVideoDecoder"
echo "   Firefox: media.ffmpeg.vaapi.enabled=true"
echo ""
echo "5. Consider using earlyoom for better OOM handling:"
echo "   sudo pacman -S earlyoom"
echo "   sudo systemctl enable --now earlyoom"
echo ""

echo "✓ Installation complete!"
echo ""
echo "Recommended next steps:"
echo "1. Edit /etc/fstab with new btrfs mount options"
echo "2. Reboot to apply all changes"
echo "3. Monitor with: ananicy-cpp -a (check rules) and htop"
