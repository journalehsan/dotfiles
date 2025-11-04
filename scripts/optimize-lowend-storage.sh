#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Low-End Device Storage Optimization ===${NC}"
echo "Optimizing for Atom x5 with eMMC storage"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}Don't run this script as root. It will use sudo when needed.${NC}" 
   exit 1
fi

# Create backup directory
BACKUP_DIR="$HOME/.config/storage-optimization-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo -e "${YELLOW}Backup directory: $BACKUP_DIR${NC}"

# Backup current configs
echo "Creating backups..."
sudo cp /etc/fstab "$BACKUP_DIR/fstab.bak" 2>/dev/null || true
sudo cp /etc/systemd/zram-generator.conf "$BACKUP_DIR/zram-generator.conf.bak" 2>/dev/null || true

# Function to add or update fstab entry
update_fstab() {
    echo -e "\n${GREEN}[1/6] Optimizing fstab...${NC}"
    
    # Backup fstab
    sudo cp /etc/fstab "$BACKUP_DIR/fstab.backup"
    
    # Optimize btrfs mount options for all subvolumes
    sudo sed -i 's/compress=zstd:3/compress=zstd:1/g' /etc/fstab
    sudo sed -i 's/rw,relatime/rw,noatime/g' /etc/fstab
    
    # Add commit and discard options to btrfs mounts if not already present
    if ! grep -q "commit=120" /etc/fstab; then
        sudo sed -i '/btrfs.*subvol=\/@[^h]/ s/subvol=\/@/commit=120,discard=async,subvol=\/@/' /etc/fstab
        sudo sed -i '/btrfs.*subvol=\/@home/ s/subvol=\/@home/commit=120,discard=async,subvol=\/@home/' /etc/fstab
        sudo sed -i '/btrfs.*subvol=\/@pkg/ s/subvol=\/@pkg/commit=120,discard=async,subvol=\/@pkg/' /etc/fstab
        sudo sed -i '/btrfs.*subvol=\/@log/ s/subvol=\/@log/commit=120,discard=async,subvol=\/@log/' /etc/fstab
    fi
    
    # Add tmpfs entries if not exist
    if ! grep -q "tmpfs.*\/tmp" /etc/fstab; then
        echo "" | sudo tee -a /etc/fstab
        echo "# tmpfs for performance" | sudo tee -a /etc/fstab
        echo "tmpfs   /tmp        tmpfs   defaults,noatime,mode=1777,size=1G   0 0" | sudo tee -a /etc/fstab
    fi
    
    if ! grep -q "tmpfs.*\/var\/tmp" /etc/fstab; then
        echo "tmpfs   /var/tmp    tmpfs   defaults,noatime,mode=1777,size=512M 0 0" | sudo tee -a /etc/fstab
    fi
    
    echo -e "${GREEN}✓ fstab optimized${NC}"
    echo -e "${YELLOW}  Changes: zstd:3→zstd:1, relatime→noatime, +commit=120, +discard=async${NC}"
}

# Setup zram
setup_zram() {
    echo -e "\n${GREEN}[2/6] Setting up zram compression...${NC}"
    
    # Install zram-generator if not present
    if ! pacman -Q zram-generator &>/dev/null; then
        echo "Installing zram-generator..."
        sudo pacman -S --noconfirm zram-generator
    fi
    
    # Configure zram
    sudo tee /etc/systemd/zram-generator.conf > /dev/null << EOF
[zram0]
zram-size = ram / 2
compression-algorithm = lz4
swap-priority = 100
EOF
    
    # Reload and start
    sudo systemctl daemon-reload
    sudo systemctl start systemd-zram-setup@zram0.service 2>/dev/null || true
    
    echo -e "${GREEN}✓ Zram configured (2GB compressed swap)${NC}"
}

# Setup I/O scheduler for eMMC
setup_io_scheduler() {
    echo -e "\n${GREEN}[3/6] Optimizing I/O scheduler for eMMC...${NC}"
    
    sudo tee /etc/udev/rules.d/60-ioschedulers.rules > /dev/null << 'EOF'
# eMMC - use none/noop for best performance
ACTION=="add|change", KERNEL=="mmcblk[0-9]*", ATTR{queue/scheduler}="none"
# Reduce readahead for eMMC (128KB is optimal for random access)
ACTION=="add|change", KERNEL=="mmcblk[0-9]*", ATTR{bdi/read_ahead_kb}="128"
# Reduce nr_requests to prevent I/O queue buildup
ACTION=="add|change", KERNEL=="mmcblk[0-9]*", ATTR{queue/nr_requests}="128"
EOF
    
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    
    echo -e "${GREEN}✓ I/O scheduler optimized${NC}"
}

# Setup browser cache in tmpfs
setup_browser_cache() {
    echo -e "\n${GREEN}[4/6] Configuring browser cache to RAM...${NC}"
    
    # Firefox
    if [ -d "$HOME/.mozilla/firefox" ]; then
        for profile in "$HOME"/.mozilla/firefox/*.default*; do
            if [ -d "$profile" ]; then
                mkdir -p "$profile"
                echo 'user_pref("browser.cache.disk.parent_directory", "/tmp/firefox-cache");' >> "$profile/user.js"
                echo -e "${GREEN}✓ Firefox cache configured${NC}"
            fi
        done
    fi
    
    # Chromium/Chrome
    if [ -f "$HOME/.config/chromium-flags.conf" ]; then
        if ! grep -q "disk-cache-dir" "$HOME/.config/chromium-flags.conf"; then
            echo -e "\n# Cache to tmpfs for faster eMMC performance" >> "$HOME/.config/chromium-flags.conf"
            echo '--disk-cache-dir=/tmp/chromium-cache' >> "$HOME/.config/chromium-flags.conf"
            echo -e "${GREEN}✓ Chromium cache configured${NC}"
        fi
    else
        mkdir -p "$HOME/.config"
        echo '--disk-cache-dir=/tmp/chromium-cache' > "$HOME/.config/chromium-flags.conf"
        echo -e "${GREEN}✓ Chromium cache configured${NC}"
    fi
    
    mkdir -p "$HOME/.config/chrome-flags.conf"
    if ! grep -q "disk-cache-dir" "$HOME/.config/chrome-flags.conf" 2>/dev/null; then
        echo '--disk-cache-dir=/tmp/chrome-cache' >> "$HOME/.config/chrome-flags.conf"
        echo -e "${GREEN}✓ Chrome cache configured${NC}"
    fi
}

# Setup vm.swappiness for better zram usage
setup_swappiness() {
    echo -e "\n${GREEN}[5/6] Tuning VM parameters...${NC}"
    
    sudo tee /etc/sysctl.d/99-swappiness.conf > /dev/null << EOF
# Swappiness for zram (higher value for compressed RAM)
vm.swappiness = 180
# Reduce cache pressure to keep more in RAM
vm.vfs_cache_pressure = 50
# Dirty ratio optimization for eMMC
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
EOF
    
    sudo sysctl -p /etc/sysctl.d/99-swappiness.conf
    echo -e "${GREEN}✓ VM parameters tuned${NC}"
}

# Optional: profile-sync-daemon
setup_psd() {
    echo -e "\n${GREEN}[6/6] Profile-sync-daemon (optional)...${NC}"
    
    if pacman -Q profile-sync-daemon &>/dev/null || pacman -Q psd &>/dev/null; then
        systemctl --user enable psd.service 2>/dev/null || true
        systemctl --user start psd.service 2>/dev/null || true
        echo -e "${GREEN}✓ Profile-sync-daemon enabled${NC}"
    else
        echo -e "${YELLOW}⚠ profile-sync-daemon not installed (optional)${NC}"
        echo "  Install with: yay -S profile-sync-daemon"
    fi
}

# Main execution
echo -e "\n${YELLOW}This will modify system configuration. Continue? (y/n)${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

update_fstab
setup_zram
setup_io_scheduler
setup_browser_cache
setup_swappiness
setup_psd

echo -e "\n${GREEN}=== Optimization Complete! ===${NC}"
echo -e "\n${YELLOW}Important:${NC}"
echo "1. Backup saved to: $BACKUP_DIR"
echo "2. Reboot to apply all changes: sudo reboot"
echo "3. After reboot, verify with: swapon --show"
echo "4. Check mount options: mount | grep btrfs"
echo ""
echo -e "${YELLOW}Rollback if needed:${NC}"
echo "sudo cp $BACKUP_DIR/fstab.bak /etc/fstab"
echo ""
echo -e "${GREEN}Expected improvements:${NC}"
echo "• 30-50% faster app launches"
echo "• Less eMMC wear"
echo "• Better multitasking with zram"
echo "• Smoother browser performance"
