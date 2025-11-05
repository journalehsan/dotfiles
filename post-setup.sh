#!/usr/bin/env bash
set -Eeuo pipefail

# Post-install automation for a MacBook Pro 2017 running Arch (Omarchy) + Hyperland.
# The script installs base packages, hardware drivers, and performance tweaks matching
# the curated checklist, keeping actions idempotent so it can be rerun safely.

usage() {
  cat <<'EOF'
Usage: ./post-setup.sh [options]

Options:
  --skip-update     Skip the initial sudo pacman -Syu upgrade step
  --skip-aur        Skip all AUR installs (requires AUR_HELPER env otherwise)
  --no-optional     Skip optional extras (camera, fan control, Thunderbolt)
  --dry-run         Show what would happen without executing commands
  -h, --help        Show this help message

Environment overrides:
  PACMAN_ARGS="--needed --noconfirm"   Extra flags passed to pacman
  AUR_HELPER=paru                       Change the AUR helper command (default: yay)
  AUR_ARGS="--needed --noconfirm"      Extra flags passed to the AUR helper
EOF
}

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
error() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }
success() { printf '[ OK ] %s\n' "$*"; }

SKIP_UPDATE=0
SKIP_AUR=0
INSTALL_OPTIONAL=1
DRY_RUN=0

while (($#)); do
  case "$1" in
    --skip-update) SKIP_UPDATE=1 ;;
    --skip-aur) SKIP_AUR=1 ;;
    --no-optional) INSTALL_OPTIONAL=0 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) error "Unknown option: $1" ;;
  esac
  shift
done

((EUID == 0)) && warn "Run this script as a regular user with sudo privileges, not as root."

command -v pacman >/dev/null 2>&1 || error "pacman not found. This script targets Arch-based systems."

PACMAN_FLAGS=(--needed)
if [[ -n "${PACMAN_ARGS:-}" ]]; then
  read -ra PACMAN_FLAGS <<<"${PACMAN_ARGS}"
fi

AUR_HELPER=${AUR_HELPER:-yay}
AUR_FLAGS=(--needed)
if [[ -n "${AUR_ARGS:-}" ]]; then
  read -ra AUR_FLAGS <<<"${AUR_ARGS}"
fi

run_cmd() {
  local desc="$1"
  shift
  info "$desc"
  if ((DRY_RUN)); then
    info "  -> (dry-run) $*"
    return 0
  fi
  set +e
  "$@"
  local status=$?
  set -e
  if ((status != 0)); then
    error "Command failed ($status): $*"
  fi
}

run_cmd_optional() {
  local desc="$1"
  shift
  info "$desc"
  if ((DRY_RUN)); then
    info "  -> (dry-run) $*"
    return 0
  fi
  set +e
  "$@"
  local status=$?
  set -e
  if ((status != 0)); then
    warn "Command failed ($status): $*"
    return $status
  fi
  return 0
}

ensure_line() {
  local file="$1"
  local line="$2"
  local needs_sudo="${3:-1}"
  if ((DRY_RUN)); then
    info "Would ensure line in $file: $line"
    return
  fi
  if ((needs_sudo)); then
    sudo mkdir -p "$(dirname "$file")"
    sudo touch "$file"
    if sudo grep -Fxq "$line" "$file"; then
      info "Line already present in $file"
    else
      info "Appending line to $file"
      echo "$line" | sudo tee -a "$file" >/dev/null
    fi
  else
    mkdir -p "$(dirname "$file")"
    touch "$file"
    if grep -Fxq "$line" "$file"; then
      info "Line already present in $file"
    else
      info "Appending line to $file"
      echo "$line" >>"$file"
    fi
  fi
}

write_file_if_changed() {
  local file="$1"
  local content="$2"
  local mode="${3:-644}"
  if ((DRY_RUN)); then
    info "Would write to $file"
    return
  fi
  sudo mkdir -p "$(dirname "$file")"
  local tmp
  tmp=$(mktemp)
  printf '%s\n' "$content" >"$tmp"
  if sudo test -f "$file" && sudo cmp -s "$tmp" "$file"; then
    info "No changes needed for $file"
  else
    info "Updating $file"
    sudo install -m "$mode" "$tmp" "$file"
  fi
  rm -f "$tmp"
}

declare -i MKINIT_NEEDS_REBUILD=0

ensure_i915_in_mkinitcpio() {
  local file="/etc/mkinitcpio.conf"
  if ((DRY_RUN)); then
    info "Would ensure i915 is listed in MODULES within $file"
    MKINIT_NEEDS_REBUILD=1
    return
  fi
  if ! sudo test -f "$file"; then
    warn "$file not found; skipping mkinitcpio adjustments."
    return
  fi
  if sudo grep -Eq '^MODULES=.*\bi915\b' "$file"; then
    info "i915 already declared in MODULES"
    return
  fi
  local backup="/etc/mkinitcpio.conf.bak.$(date +%Y%m%d%H%M%S)"
  info "Adding i915 to MODULES (backup: $backup)"
  sudo cp "$file" "$backup"
  if sudo grep -Eq '^MODULES=\([[:space:]]*\)$' "$file"; then
    sudo sed -i -E 's/^MODULES=\([[:space:]]*\)$/MODULES=(i915)/' "$file"
  else
    sudo sed -i 's/^MODULES=(/MODULES=(i915 /' "$file"
  fi
  MKINIT_NEEDS_REBUILD=1
}

pacman_groups=(
  "System basics|base-devel linux-headers git"
  "Wayland stack|hyperland waybar wofi xdg-desktop-portal-hyprland dunst kitty"
  "Intel graphics|mesa vulkan-intel libva-intel-driver intel-media-driver"
  "Audio stack|alsa-utils pipewire pipewire-pulse pipewire-alsa wireplumber"
  "Power tuning|tlp powertop thermald systemd-zram-generator"
  "Input & gestures|libinput libinput-gestures xorg-xinput touchegg"
  "Thunderbolt tools|bolt"
)

aur_groups=(
  "Broadcom Wi-Fi|broadcom-wl-dkms"
  "MacBook hardware|apple-touchbar-driver-git macbook-lid macbook-setup touchbar-linux-gui macbook-kbd-led macbook-als"
)

optional_aur_groups=(
  "Camera firmware|facetimehd-firmware"
  "Fan control|mbpfan"
)

if (( !SKIP_UPDATE )); then
  run_cmd "Updating system packages via pacman -Syu" sudo pacman -Syu
else
  info "Skipping system update as requested."
fi

install_pacman_group() {
  local label="$1"
  shift
  local packages=("$@")
  (( ${#packages[@]} == 0 )) && return
  run_cmd "Installing $label packages via pacman" sudo pacman -S "${PACMAN_FLAGS[@]}" "${packages[@]}"
}

install_aur_group() {
  local label="$1"
  shift
  local packages=("$@")
  (( ${#packages[@]} == 0 )) && return
  run_cmd "Installing $label packages via ${AUR_HELPER}" "$AUR_HELPER" -S "${AUR_FLAGS[@]}" "${packages[@]}"
}

for entry in "${pacman_groups[@]}"; do
  IFS="|" read -r label pkg_string <<<"$entry"
  read -ra pkgs <<<"$pkg_string"
  install_pacman_group "$label" "${pkgs[@]}"
done

if ((SKIP_AUR)); then
  warn "Skipping all AUR packages (--skip-aur)."
else
  if ! command -v "$AUR_HELPER" >/dev/null 2>&1; then
    warn "AUR helper '$AUR_HELPER' not found. Skipping AUR installs."
  else
    for entry in "${aur_groups[@]}"; do
      IFS="|" read -r label pkg_string <<<"$entry"
      read -ra pkgs <<<"$pkg_string"
      install_aur_group "$label" "${pkgs[@]}"
    done
    if ((INSTALL_OPTIONAL)); then
      for entry in "${optional_aur_groups[@]}"; do
        IFS="|" read -r label pkg_string <<<"$entry"
        read -ra pkgs <<<"$pkg_string"
        install_aur_group "$label" "${pkgs[@]}"
      done
    else
      info "Optional extras disabled (--no-optional)."
    fi
  fi
fi

ensure_line "/etc/environment" "LIBVA_DRIVER_NAME=iHD"
ensure_line "/etc/environment" "vblank_mode=0"
ensure_line "/etc/environment" '__GL_YIELD="USLEEP"'

ensure_line "/etc/modules-load.d/broadcom.conf" "wl"

write_file_if_changed "/etc/modprobe.d/audio-fix.conf" "options snd_hda_intel model=mbp101"

write_file_if_changed "/etc/systemd/zram-generator.conf" $'[zram0]\nzram-size = ram / 2\ncompression-algorithm = zstd'

write_file_if_changed "/etc/systemd/system/powertop-autotune.service" $'[Unit]\nDescription=Powertop auto tune\nAfter=multi-user.target\n\n[Service]\nType=oneshot\nExecStart=/usr/bin/powertop --auto-tune\n\n[Install]\nWantedBy=multi-user.target'

ensure_i915_in_mkinitcpio

run_cmd "Enabling tlp and thermald services" sudo systemctl enable --now tlp thermald
run_cmd_optional "Enabling powertop-autotune service" sudo systemctl enable --now powertop-autotune.service
run_cmd_optional "Enabling weekly SSD trim timer" sudo systemctl enable --now fstrim.timer
run_cmd_optional "Disabling Bluetooth service for power savings" sudo systemctl disable --now bluetooth.service
run_cmd_optional "Disabling CUPS service" sudo systemctl disable --now cups.service
run_cmd_optional "Masking systemd-networkd-wait-online service" sudo systemctl mask --now systemd-networkd-wait-online.service

run_cmd_optional "Adding current user to input group" sudo gpasswd -a "$USER" input

if command -v libinput-gestures-setup >/dev/null 2>&1; then
  run_cmd_optional "Enabling libinput-gestures autostart" libinput-gestures-setup autostart
else
  warn "libinput-gestures-setup not found; ensure libinput-gestures installed correctly."
fi

if command -v systemctl >/dev/null 2>&1; then
  run_cmd_optional "Enabling touchegg (user) service" systemctl --user enable --now touchegg.service
else
  warn "systemctl not available; skipping touchegg --user enablement."
fi

if ! ((SKIP_AUR)) && command -v "$AUR_HELPER" >/dev/null 2>&1; then
  run_cmd_optional "Loading Broadcom wl module" sudo modprobe wl
  if ((INSTALL_OPTIONAL)); then
    run_cmd_optional "Enabling mbpfan service" sudo systemctl enable --now mbpfan.service
  fi
fi

if ((MKINIT_NEEDS_REBUILD)) && (( !DRY_RUN )); then
  run_cmd "Rebuilding initramfs with mkinitcpio" sudo mkinitcpio -P
elif ((MKINIT_NEEDS_REBUILD)) && ((DRY_RUN)); then
  info "mkinitcpio would be rebuilt (dry-run)."
fi

success "MacBook Pro 2017 post-setup tasks completed."
if ((DRY_RUN)); then
  warn "Dry-run mode was enabled; no changes were applied."
else
  info "Reboot recommended to apply kernel module and power-management tweaks."
fi
