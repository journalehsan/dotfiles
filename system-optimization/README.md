# Arch Linux Optimizations for Intel Celeron N4000 (4GB RAM, eMMC)

## Overview
This configuration optimizes your system for low-power hardware with limited RAM and eMMC storage.

## Key Optimizations

### 1. Memory Management (`99-celeron-optimizations.conf`)
- **vm.swappiness = 10**: Reduces swap usage (zram is faster)
- **vm.vfs_cache_pressure = 50**: Keeps more cache in memory
- **vm.dirty_ratio = 40/20**: Reduces eMMC write frequency
- **vm.page-cluster = 0**: Optimizes for zram

### 2. Zram (`zram-config.conf`)
- **50% of RAM**: 2GB compressed swap in memory
- **zstd compression**: Best balance of speed/ratio
- **Priority 100**: Ensures zram is used before disk swap

### 3. Btrfs Mount Options
- **noatime**: Reduces write operations
- **discard=async**: Efficient TRIM for eMMC
- **commit=120**: Reduces commit frequency (less writes)
- **compress=zstd:3**: Already configured ✓

### 4. Ananicy-cpp Rules
Priority hierarchy for Hyprland:
1. **Realtime**: Hyprland, PipeWire (smooth UI/audio)
2. **High**: Waybar, launchers (responsive WM)
3. **Normal**: Terminals, file managers
4. **Low**: Browsers (resource-heavy)
5. **Idle**: Background apps, sync services

## Installation

```bash
cd ~/dotfiles/system-optimization
./install-and-apply.sh
```

## Manual Steps

### 1. Update /etc/fstab
```bash
sudo nano /etc/fstab
```
Add to root and all subvolumes:
```
noatime,discard=async,commit=120
```

### 2. Enable fstrim
```bash
sudo systemctl enable --now fstrim.timer
```

### 3. Limit journal size (reduces eMMC wear)
```bash
sudo journalctl --vacuum-size=50M
echo 'SystemMaxUse=50M' | sudo tee -a /etc/systemd/journald.conf
```

### 4. Optional: earlyoom (better OOM handling)
```bash
sudo pacman -S earlyoom
sudo systemctl enable --now earlyoom
```

## Monitoring

Check if optimizations are working:

```bash
# Check ananicy-cpp rules
ananicy-cpp -a

# Monitor memory/swap
watch -n1 'free -h && echo && swapon --show'

# Check zram efficiency
zramctl

# Monitor I/O
iotop

# Check active sysctl values
sysctl vm.swappiness vm.dirty_ratio vm.vfs_cache_pressure
```

## Expected Results
- **Lower latency**: Hyprland/audio prioritized
- **Less eMMC wear**: Reduced writes via noatime, commit times
- **Better RAM usage**: Optimized cache pressure and swappiness
- **Smoother multitasking**: Process prioritization via ananicy-cpp
- **Extended battery**: Lower I/O overhead

## Troubleshooting

### High memory usage
```bash
# Check what's using memory
ps aux --sort=-%mem | head -n 10

# Check zram compression ratio
zramctl
```

### System feels slow
```bash
# Check if ananicy-cpp is running
systemctl status ananicy-cpp

# Check current priorities
ps -eo pid,nice,comm | grep -E 'hyprland|waybar'
```

### Too much swapping
```bash
# Lower swappiness further
sudo sysctl -w vm.swappiness=5
```

## Revert Changes

```bash
# Restore original sysctl
sudo rm /etc/sysctl.d/99-celeron-optimizations.conf
sudo sysctl --system

# Disable ananicy-cpp
sudo systemctl disable --now ananicy-cpp

# Restore original zram config
sudo cp /etc/systemd/zram-generator.conf.bak /etc/systemd/zram-generator.conf
```
