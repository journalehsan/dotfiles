#!/bin/bash

# Disk and memory cleanup utility (Arch-focused, Linux/macOS aware)
# - Safely cleans caches, temp files, journals, etc.
# - Optional RAM freeing via kernel drop_caches/compaction (Linux) or purge (macOS)
# - Supports dry-run and confirmations

set -Eeuo pipefail
IFS=$'\n\t'

# ---------- Helpers ----------
command_exists() { command -v "$1" >/dev/null 2>&1; }

log()   { printf "[info] %s\n" "$*"; }
warn()  { printf "[warn] %s\n" "$*" >&2; }
error() { printf "[err ] %s\n" "$*" >&2; }

ASSUME_YES=0
DRY_RUN=0
FREE_RAM=0
AGGRESSIVE=0
DOCKER_PRUNE=0
JOURNAL_RETENTION_DAYS=7
JOURNAL_MAX_SIZE=200M
KEEP_PACMAN_VERSIONS=3

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf "+ %s\n" "$*"
  else
    bash -c "$*"
  fi
}

run_sudo() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf "+ sudo %s\n" "$*"
  else
    sudo bash -c "$*"
  fi
}

confirm() {
  local prompt=${1:-"Proceed?"}
  if [[ $ASSUME_YES -eq 1 ]]; then return 0; fi
  read -r -p "$prompt [y/N] " ans || true
  [[ ${ans:-} =~ ^[Yy]$ ]]
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -y, --yes               Assume yes for prompts
  -n, --dry-run           Print actions without executing
      --free-ram          Perform RAM cleanup (cache drop/compaction)
      --aggressive        More aggressive cleanup (RAM: drop_caches=3 + swap reset)
      --docker            Also prune Docker (system prune -af --volumes)
      --journal-days N    Keep N days of journal logs (default: $JOURNAL_RETENTION_DAYS)
      --journal-size SZ   Limit journals to size SZ (default: $JOURNAL_MAX_SIZE)
      --keep-versions N   Keep N pacman package versions (default: $KEEP_PACMAN_VERSIONS)
  -h, --help              Show this help
EOF
}

# ---------- Args ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes) ASSUME_YES=1 ;;
    -n|--dry-run) DRY_RUN=1 ;;
    --free-ram) FREE_RAM=1 ;;
    --aggressive) AGGRESSIVE=1 ;;
    --docker) DOCKER_PRUNE=1 ;;
    --journal-days) shift; JOURNAL_RETENTION_DAYS="${1:-$JOURNAL_RETENTION_DAYS}" ;;
    --journal-size) shift; JOURNAL_MAX_SIZE="${1:-$JOURNAL_MAX_SIZE}" ;;
    --keep-versions) shift; KEEP_PACMAN_VERSIONS="${1:-$KEEP_PACMAN_VERSIONS}" ;;
    -h|--help) usage; exit 0 ;;
    *) error "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift || true
done

trap 'error "Failed at line $LINENO"' ERR

# ---------- Start ----------
log "Starting cleanup..."
log "Disk before:"; df -h / | tail -n +2

# ---------- Pacman cache ----------
if command_exists pacman; then
  log "Cleaning pacman cache..."
  if command_exists paccache; then
    run_sudo "paccache -r -k $KEEP_PACMAN_VERSIONS"
    # Remove uninstalled package caches
    run_sudo "paccache -ruk0"
  else
    warn "paccache not found; falling back to pacman -Sc"
    run_sudo "pacman -Sc --noconfirm"
  fi
fi

# ---------- AUR helper caches ----------
log "Cleaning AUR helper caches..."
for d in "$HOME/.cache/paru" "$HOME/.cache/yay" "$HOME/builds"; do
  [[ -d "$d" ]] && run "rm -rf \"$d\""
done

# ---------- User caches ----------
log "Cleaning user caches..."
[[ -d "$HOME/.cache/mesa_shader_cache" ]] && run "rm -rf \"$HOME/.cache/mesa_shader_cache\""
[[ -d "$HOME/.cache/fontconfig" ]] && run "rm -rf \"$HOME/.cache/fontconfig\""
run "find \"$HOME/.cache\" -type f -name '*.cache' -delete 2>/dev/null || true"

# Thumbnails
log "Cleaning thumbnail caches..."
run "rm -rf \"$HOME/.cache/thumbnails/large\" 2>/dev/null || true"
run "rm -rf \"$HOME/.cache/thumbnails/normal\" 2>/dev/null || true"
run "find \"$HOME/.cache/thumbnails\" -type f -atime +30 -delete 2>/dev/null || true"

# ---------- Temp files ----------
log "Cleaning temporary files older than 7 days in /tmp..."
run "find /tmp -type f -atime +7 -delete 2>/dev/null || true"

# ---------- Language/runtime caches ----------
if command_exists pip; then log "Purging pip cache..."; run "pip cache purge 2>/dev/null || true"; fi
if command_exists pip3; then log "Purging pip3 cache..."; run "pip3 cache purge 2>/dev/null || true"; fi
if command_exists npm; then log "Cleaning npm cache..."; run "npm cache clean --force 2>/dev/null || true"; fi
# cargo-cache subcommand (cargo-cache) if available
if command_exists cargo; then
  log "Cleaning cargo cache (if cargo-cache is installed)..."
  run "cargo cache --autoclean 2>/dev/null || true"
fi

# ---------- Journals ----------
if command_exists journalctl; then
  log "Vacuuming systemd journals (keep ${JOURNAL_RETENTION_DAYS}d, limit ${JOURNAL_MAX_SIZE})..."
  run_sudo "journalctl --vacuum-time=${JOURNAL_RETENTION_DAYS}d --vacuum-size=${JOURNAL_MAX_SIZE}"
fi

# ---------- Browser caches ----------
log "Cleaning browser caches..."
for d in \
  "$HOME/.cache/google-chrome" \
  "$HOME/.cache/chromium" \
  "$HOME/.cache/mozilla/firefox" \
  "$HOME/.cache/BraveSoftware" \
  "$HOME/.cache/microsoft-edge" \
  "$HOME/.cache/zen-browser"; do
  [[ -d "$d" ]] && run "rm -rf \"$d/*\" 2>/dev/null || true"
done

# ---------- Flatpak ----------
if command_exists flatpak; then
  log "Removing unused Flatpak refs..."
  run "flatpak uninstall --unused -y 2>/dev/null || true"
fi

# ---------- Docker (optional) ----------
if [[ $DOCKER_PRUNE -eq 1 ]] && command_exists docker; then
  if confirm "Prune Docker (dangling images, containers, networks, volumes)?"; then
    run "docker system prune -af --volumes"
  fi
fi

# ---------- RAM cleanup (optional) ----------
free_ram() {
  log "RAM before:"; free -h || true
  local os; os=$(uname -s || echo unknown)

  if [[ "$os" == "Darwin" ]]; then
    if command_exists purge; then
      if confirm "Run macOS purge to drop disk buffers?"; then
        run_sudo "purge"
      fi
    else
      warn "macOS 'purge' not available."
    fi
  else
    # Linux/Other using drop_caches and compaction
    local level=1
    [[ $AGGRESSIVE -eq 1 ]] && level=3
    if confirm "Drop Linux caches (echo $level > /proc/sys/vm/drop_caches)?"; then
      run_sudo "sync; echo $level > /proc/sys/vm/drop_caches"
    fi
    # Optional memory compaction
    if [[ -w /proc/sys/vm/compact_memory || $DRY_RUN -eq 1 ]]; then
      if confirm "Trigger memory compaction?"; then
        run_sudo "echo 1 > /proc/sys/vm/compact_memory"
      fi
    fi
    # Optional swap reset for aggressive mode
    if [[ $AGGRESSIVE -eq 1 ]] && command_exists swapon; then
      if [[ $(swapon --noheadings | wc -l | tr -d ' ') -gt 0 ]]; then
        if confirm "Temporarily disable+enable swap to drop cached swap pages?"; then
          run_sudo "swapoff -a && swapon -a"
        fi
      fi
    fi
  fi

  log "RAM after:"; free -h || true
}

if [[ $FREE_RAM -eq 1 ]]; then
  free_ram
fi

log "Cleanup completed!"
log "Disk after:"; df -h / | tail -n +2
