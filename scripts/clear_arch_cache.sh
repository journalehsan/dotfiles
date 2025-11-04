#!/usr/bin/env bash
# Clean up user and system caches safely on Arch Linux.
set -euo pipefail

KEEP_PACKAGES=3
JOURNAL_MODE="time"
JOURNAL_VALUE="14d"
LOG_RETENTION_DAYS=14
DRY_RUN=false
AUTO_CONFIRM=false
TARGET_HOME="${HOME}"
DO_HOME=false
DO_SYSTEM=false
PACMAN_SYNC_CLEAN=false
CLEAR_SYSTEM_TMP=true

usage() {
  cat <<'EOF'
Usage: clear_arch_cache.sh [options]

Options:
  --home                Clean user-level caches in $HOME.
  --system              Clean system caches (requires root).
  --full                Clean both user and system caches.
  --target-home PATH    Override the home directory to clean (defaults to $HOME).
  --keep-packages N     Keep the newest N pacman packages (default: 3).
  --journal-time VAL    Vacuum journal logs older than VAL (default: 14d).
  --journal-size SIZE   Vacuum journal logs until SIZE is reached.
  --log-days N          Remove rotated logs older than N days (default: 14).
  --dry-run             Show what would be removed without deleting anything.
  --yes, -y             Skip confirmation prompts.
  --pacman-sync         Also clear /var/cache/pacman/sync (pacman -Scc).
  --skip-tmp            Skip clearing /tmp and /var/tmp.
  --help                Show this help.

Examples:
  # Clean your own caches only
  ./clear_arch_cache.sh --home

  # Clean everything (requires sudo)
  sudo ./clear_arch_cache.sh --full --yes

EOF
}

info() {
  printf '[INFO] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

confirm() {
  local prompt=$1
  if $AUTO_CONFIRM; then
    return 0
  fi
  read -rp "$prompt [y/N] " reply
  [[ ${reply,,} == y || ${reply,,} == yes ]]
}

clear_dir_contents() {
  local dir=$1
  local description=$2
  local remove_dir=${3:-false}

  [[ -e $dir ]] || return 0

  if $DRY_RUN; then
    info "Would clear ${description}: ${dir}"
    return 0
  fi

  if ! confirm "Clear ${description} at ${dir}?"; then
    info "Skipped ${description}"
    return 0
  fi

  info "Clearing ${description} at ${dir}"
  if [[ -d $dir ]]; then
    if $remove_dir; then
      rm -rf -- "$dir"
      mkdir -p -- "$dir"
    else
      find "$dir" -mindepth 1 -maxdepth 1 -print0 | xargs -0 rm -rf --
    fi
  else
    rm -f -- "$dir"
  fi
}

run_step() {
  local description=$1
  shift
  if $DRY_RUN; then
    info "Would run: $description :: $*"
    return 0
  fi

  if ! confirm "${description}?"; then
    info "Skipped: ${description}"
    return 0
  fi

  info "Running: ${description}"
  "$@"
}

clean_home() {
  local home_cache=${XDG_CACHE_HOME:-${TARGET_HOME}/.cache}
  clear_dir_contents "$home_cache" "user cache directory"
  clear_dir_contents "${TARGET_HOME}/.cache/thumbnails" "thumbnail cache"
  clear_dir_contents "${TARGET_HOME}/.local/share/Trash/files" "Trash files"
  clear_dir_contents "${TARGET_HOME}/.local/share/Trash/info" "Trash metadata"
  clear_dir_contents "${TARGET_HOME}/.npm/_cacache" "npm cache"
  clear_dir_contents "${TARGET_HOME}/.cache/yay" "yay AUR helper cache"
  clear_dir_contents "${TARGET_HOME}/.cache/paru" "paru AUR helper cache"
  clear_dir_contents "${TARGET_HOME}/.cache/pikaur" "pikaur AUR helper cache"
  clear_dir_contents "${TARGET_HOME}/.cache/pip" "pip cache"
  clear_dir_contents "${TARGET_HOME}/.cache/mozilla/firefox" "Firefox cache"
}

clean_pacman_cache() {
  if command -v paccache >/dev/null 2>&1; then
    run_step "Prune cached pacman packages (keep ${KEEP_PACKAGES})" \
      paccache -r -k "$KEEP_PACKAGES"
    run_step "Remove uninstalled package cache" \
      paccache -ruk1
  else
    warn "paccache not found; falling back to pacman -Sc"
    run_step "Remove stale pacman packages" \
      pacman -Sc --noconfirm
  fi

  if $PACMAN_SYNC_CLEAN; then
    run_step "Clear pacman sync database cache (pacman -Scc)" \
      pacman -Scc --noconfirm
  fi
}

clean_tmp_dirs() {
  [[ -d /tmp ]] && run_step "Purge /tmp" bash -lc 'find /tmp -mindepth 1 -xdev -print0 | xargs -0 rm -rf --'
  [[ -d /var/tmp ]] && run_step "Purge /var/tmp" bash -lc 'find /var/tmp -mindepth 1 -xdev -print0 | xargs -0 rm -rf --'
}

vacuum_journal() {
  if ! command -v journalctl >/dev/null 2>&1; then
    warn "journalctl not available; skipping journal vacuum"
    return 0
  fi

  if [[ $JOURNAL_MODE == "size" ]]; then
    run_step "Vacuum journal to ${JOURNAL_VALUE}" journalctl --vacuum-size="$JOURNAL_VALUE"
  else
    run_step "Vacuum journal entries older than ${JOURNAL_VALUE}" journalctl --vacuum-time="$JOURNAL_VALUE"
  fi
}

prune_logs() {
  local find_expr=(-type f \( -name '*.log.*' -o -name '*.old' -o -name '*.gz' -o -name '*.xz' \) -mtime +"${LOG_RETENTION_DAYS}")
  if $DRY_RUN; then
    info "Would prune rotated logs older than ${LOG_RETENTION_DAYS} days in /var/log"
    return 0
  fi

  if ! confirm "Delete rotated logs in /var/log older than ${LOG_RETENTION_DAYS} days?"; then
    info "Skipped log pruning"
    return 0
  fi

  info "Pruning rotated logs older than ${LOG_RETENTION_DAYS} days"
  find /var/log "${find_expr[@]}" -print -delete
}

clean_system() {
  clean_pacman_cache
  vacuum_journal
  prune_logs
  if $CLEAR_SYSTEM_TMP; then
    clean_tmp_dirs
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --home)
        DO_HOME=true
        ;;
      --system)
        DO_SYSTEM=true
        ;;
      --full)
        DO_HOME=true
        DO_SYSTEM=true
        ;;
      --target-home)
        shift
        [[ $# -gt 0 ]] || die "--target-home requires a path"
        TARGET_HOME=$1
        ;;
      --keep-packages)
        shift
        [[ $# -gt 0 ]] || die "--keep-packages requires a value"
        KEEP_PACKAGES=$1
        ;;
      --keep-packages=*)
        KEEP_PACKAGES=${1#*=}
        ;;
      --journal-time)
        shift
        [[ $# -gt 0 ]] || die "--journal-time requires a value"
        JOURNAL_MODE="time"
        JOURNAL_VALUE=$1
        ;;
      --journal-time=*)
        JOURNAL_MODE="time"
        JOURNAL_VALUE=${1#*=}
        ;;
      --journal-size)
        shift
        [[ $# -gt 0 ]] || die "--journal-size requires a value"
        JOURNAL_MODE="size"
        JOURNAL_VALUE=$1
        ;;
      --journal-size=*)
        JOURNAL_MODE="size"
        JOURNAL_VALUE=${1#*=}
        ;;
      --log-days)
        shift
        [[ $# -gt 0 ]] || die "--log-days requires a value"
        LOG_RETENTION_DAYS=$1
        ;;
      --log-days=*)
        LOG_RETENTION_DAYS=${1#*=}
        ;;
      --dry-run)
        DRY_RUN=true
        ;;
      --yes|-y)
        AUTO_CONFIRM=true
        ;;
      --pacman-sync)
        PACMAN_SYNC_CLEAN=true
        ;;
      --skip-tmp)
        CLEAR_SYSTEM_TMP=false
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
    shift || true
  done
}

main() {
  parse_args "$@"

  if ! $DO_HOME && ! $DO_SYSTEM; then
    DO_HOME=true
    if [[ $EUID -eq 0 ]]; then
      DO_SYSTEM=true
    fi
  fi

  if $DO_SYSTEM && [[ $EUID -ne 0 ]]; then
    die "--system or --full requires root privileges"
  fi

  if [[ ! -d $TARGET_HOME ]]; then
    die "Target home directory does not exist: ${TARGET_HOME}"
  fi

  info "Starting cache cleanup"
  info "Dry run: $DRY_RUN | Auto confirm: $AUTO_CONFIRM"

  if $DO_HOME; then
    info "Cleaning user caches under ${TARGET_HOME}"
    clean_home
  fi

  if $DO_SYSTEM; then
    info "Cleaning system caches"
    clean_system
  fi

  info "Cleanup complete"
}

main "$@"
