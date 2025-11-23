#!/usr/bin/env bash
# Install and configure firewalld with a Rocky Linux-style baseline on Arch.
set -euo pipefail

DEFAULT_ZONE="public"
ALLOW_SSH=true
EXTRA_SERVICES=()
EXTRA_PORTS=()

usage() {
  cat <<'EOF'
Usage: setup-firewalld.sh [options]

Options:
  --zone NAME           Set the default zone (default: public)
  --no-ssh              Do not allow SSH service
  --allow-service NAME  Allow an additional named service (repeatable)
  --allow-port PORT/PROT Allow an extra port, e.g. 51820/udp (repeatable)
  --help                Show this help

Notes:
  - Run as root (sudo ./setup-firewalld.sh ...)
  - Installs firewalld, enables and starts it.
  - Applies a public-zone baseline similar to Rocky Linux, with SSH allowed
    unless --no-ssh is provided.
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1" >&2; exit 1; }
}

require_arg() {
  local flag=$1
  local value=$2
  if [[ -z $value ]]; then
    echo "Flag ${flag} requires a value." >&2
    exit 1
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --zone)
        require_arg "$1" "${2:-}"
        DEFAULT_ZONE=$2
        shift 2
        ;;
      --no-ssh)
        ALLOW_SSH=false
        shift
        ;;
      --allow-service)
        require_arg "$1" "${2:-}"
        EXTRA_SERVICES+=("$2")
        shift 2
        ;;
      --allow-port)
        require_arg "$1" "${2:-}"
        EXTRA_PORTS+=("$2")
        shift 2
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage
        exit 1
        ;;
    esac
  done
}

warn_conflicts() {
  local conflicts=("ufw.service" "nftables.service" "iptables.service")
  for unit in "${conflicts[@]}"; do
    if systemctl is-active --quiet "$unit"; then
      echo "Warning: $unit is active and may conflict with firewalld." >&2
    fi
  done
}

add_permissions() {
  local args=(--permanent)
  $ALLOW_SSH && args+=(--add-service=ssh)
  for svc in "${EXTRA_SERVICES[@]}"; do
    [[ -n $svc ]] && args+=(--add-service="$svc")
  done
  for port in "${EXTRA_PORTS[@]}"; do
    [[ -n $port ]] && args+=(--add-port="$port")
  done

  if ((${#args[@]} > 1)); then
    firewall-cmd "${args[@]}"
  fi
}

main() {
  parse_args "$@"
  require_cmd pacman
  require_cmd systemctl

  if [[ $EUID -ne 0 ]]; then
    echo "Please run as root (e.g., sudo $0 ...)" >&2
    exit 1
  fi

  warn_conflicts

  pacman -S --needed --noconfirm firewalld

  # Ensure nftables backend is available; firewalld defaults to it on Arch.
  pacman -S --needed --noconfirm nftables

  systemctl enable --now firewalld

  # Set default zone (affects runtime and saved config).
  firewall-cmd --set-default-zone="$DEFAULT_ZONE"
  firewall-cmd --permanent --add-service=dhcpv6-client
  add_permissions
  firewall-cmd --reload

  echo "firewalld state: $(firewall-cmd --state)"
  firewall-cmd --get-active-zones
  firewall-cmd --list-all
}

main "$@"
