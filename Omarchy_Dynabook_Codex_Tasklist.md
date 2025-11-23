# Omarchy Dynabook R82/B – Codex Task List

Use this checklist inside Codex (or your Omarchy automation) to apply the post-install tuning for the Toshiba Dynabook R82/B with Core m3-6Y30, Intel HD 515, Btrfs, and Hyperland. Each task is self-contained so you can run → verify → log results.

> **Tip:** Run commands exactly as shown. If you already performed a task, mark it complete and note any deviations in your Codex log.

---

## [Task 0] Confirm Baseline
- **Goal:** Capture the current system state before tuning.
- **Run:**
  ```bash
  neofetch || fastfetch
  sudo tlp-stat -s || true
  lsblk -f
  btrfs fi usage /
  ```
- **Verify:** Save command output in your Codex notes for comparison after tuning.

## [Task 1] Install Power & Thermal Stack
- **Goal:** Enable efficient CPU and thermal management.
- **Run:**
  ```bash
  sudo pacman -S --needed tlp tlp-rdw thermald powertop
  sudo systemctl enable --now tlp thermald
  sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket
  ```
- **Verify:** `sudo tlp-stat -s` should show `Mode = battery` or `AC`, `systemctl status thermald` is `active (running)`.

## [Task 2] Tune `/etc/tlp.conf`
- **Goal:** Apply laptop-friendly CPU and SATA policies.
- **Edit:** `/etc/tlp.conf`
  ```ini
  CPU_DRIVER_OPMODE=passive
  CPU_SCALING_GOVERNOR_ON_AC=powersave
  CPU_SCALING_GOVERNOR_ON_BAT=power_save
  CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
  CPU_ENERGY_PERF_POLICY_ON_BAT=power
  SATA_LINKPWR_ON_AC=max_performance
  SATA_LINKPWR_ON_BAT=min_power
  ```
- **Run (reload):**
  ```bash
  sudo systemctl restart tlp
  sudo tlp-stat -p
  ```
- **Verify:** Ensure `Driver mode = passive`, and policies reflect the new settings.

## [Task 3] Optional – auto-cpufreq
- **Goal:** Use `auto-cpufreq` instead of TLP’s CPU control (skip if sticking with Task 2).
- **Run:**
  ```bash
  yay -S auto-cpufreq
  sudo auto-cpufreq --install
  sudo sed -i 's/^CPU_/#CPU_/g' /etc/tlp.conf
  sudo systemctl restart auto-cpufreq
  ```
- **Verify:** `auto-cpufreq --monitor` shows active management; TLP stats no longer list CPU overrides.

## [Task 4] GRUB Kernel Parameters
- **Goal:** Activate passive intel_pstate and disable watchdog noise.
- **Edit:** `/etc/default/grub`
  ```
  GRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_pstate=passive nowatchdog"
  ```
- **Run (apply):**
  ```bash
  sudo grub-mkconfig -o /boot/grub/grub.cfg
  ```
- **Verify:** After reboot, `cat /proc/cmdline` includes `intel_pstate=passive nowatchdog`.

## [Task 5] Review Btrfs Mount Options
- **Goal:** Ensure compression, async discard, and space cache v2.
- **Edit:** `/etc/fstab` (adjust UUID to match `lsblk -f` output).
  ```fstab
  UUID=xxxxxx / btrfs rw,noatime,ssd,space_cache=v2,compress=zstd:3,discard=async,subvol=@
  ```
- **Verify:** `findmnt -no OPTIONS /` lists `compress=zstd:3`, `discard=async`.

## [Task 6] Btrfs Maintenance
- **Goal:** Enable on-disk compression property and trim cadence.
- **Run:**
  ```bash
  sudo btrfs property set / compression zstd:3
  sudo systemctl enable --now fstrim.timer
  ```
- **Optional:** Install periodic balance/trim helpers.
  ```bash
  yay -S btrfsmaintenance
  sudo systemctl enable --now btrfs-balance.timer btrfs-trim.timer
  ```
- **Verify:** `sudo systemctl status fstrim.timer` is active; `btrfs property get / compression` equals `zstd:3`.

## [Task 7] Intel GPU Environment Overrides
- **Goal:** Improve stability on Intel HD 515 under Wayland.
- **Edit:** `/etc/environment`
  ```
  MESA_LOADER_DRIVER_OVERRIDE=i965
  INTEL_DEBUG=norbc
  ```
- **Verify:** Re-login and run `echo $MESA_LOADER_DRIVER_OVERRIDE`; `glxinfo -B | grep "OpenGL renderer"` shows i965.

## [Task 8] Hyperland Environment Tweaks
- **Goal:** Ensure DRM modifiers are disabled and correct card is used.
- **Edit:** `~/.config/hypr/hyprland.conf`
  ```ini
  env = WLR_DRM_NO_MODIFIERS,1
  env = WLR_DRM_DEVICES,/dev/dri/card0
  ```
- **Verify:** Restart Hyperland; check `journalctl --user -b | rg WLR_DRM` for applied variables.

## [Task 9] ZRAM Swap
- **Goal:** Provide compressed swap to absorb memory bursts.
- **Run:**
  ```bash
  sudo pacman -S --needed zram-generator
  sudo tee /etc/systemd/zram-generator.conf <<'EOF'
  [zram0]
  zram-size = ram/8
  compression-algorithm = zstd
  EOF
  sudo systemctl daemon-reload
  sudo systemctl start /dev/zram0
  ```
- **Verify:** `swapon --show` lists `/dev/zram0`; `cat /proc/swaps` confirms size ≈ RAM/8.

## [Task 10] Powertop Auto-Tune
- **Goal:** Apply kernel-level power savings.
- **Run:**
  ```bash
  sudo powertop --auto-tune
  sudo systemctl enable powertop.service
  ```
- **Verify:** `systemctl status powertop.service` is active; `sudo powertop --auto-tune` shows “Good” for tunables.

## [Task 11] Miscellaneous Quality of Life
- **Goal:** Apply optional polish items.
- **Run (select as needed):**
  ```bash
  yay -S gtklock        # Wayland-friendly lock screen
  upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep capacity
  # Optional: disable IPv6 per connection in nm-connection-editor if wake-from-sleep Wi-Fi is slow
  # PipeWire: edit /etc/pipewire/pipewire.conf -> default.clock.quantum = 512
  ```
- **Verify:** Launch `gtklock`; note battery capacity; confirm network/pulse changes behave as expected.

## [Task 12] Post-Tuning Snapshot
- **Goal:** Document improvements and ensure persistence.
- **Run:**
  ```bash
  sudo systemctl list-units --state=running | rg 'tlp|thermald|powertop|zram|fstrim'
  sudo tlp-stat -s
  btrfs fi usage /
  swapon --show
  ```
- **Verify:** Compare with Task 0 outputs; log remaining follow-ups or issues in Codex.

---

### Done!
When every task is checked off, your Dynabook should run cool, quiet, and responsive under Omarchy + Hyperland. Capture any deviations, package installs, or errors in your Codex session so you can replay or automate the adjustments later.

