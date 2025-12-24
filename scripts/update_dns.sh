#!/usr/bin/env bash
set -euo pipefail

# Adds nameserver 127.0.0.1 to /etc/resolv.conf, restarts DNS services,
# and verifies DDNS update with a success dialog when possible.

NAMESERVERS=("178.22.122.101" "185.51.200.1")
RESOLV_CONF="/etc/resolv.conf"
UPDATE_URL="https://ddns.shecan.ir/update?password=2f2b55978506b97d"

log() {
  echo "[dns-update] $*"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

notify_success() {
  local message=$1
  if command -v zenity >/dev/null 2>&1; then
    zenity --info --title="DNS update" --text="$message"
  else
    log "SUCCESS: $message"
  fi
}

notify_failure() {
  local message=$1
  if command -v zenity >/dev/null 2>&1; then
    zenity --error --title="DNS update failed" --text="$message"
  else
    log "FAIL: $message"
  fi
}

ensure_nameserver() {
  local temp_file
  temp_file=$(mktemp)

  if [ -f "$RESOLV_CONF" ]; then
    grep -v "^nameserver[[:space:]]" "$RESOLV_CONF" > "$temp_file" || true
  fi

  for ns in "${NAMESERVERS[@]}"; do
    printf "nameserver %s\n" "$ns" >> "$temp_file"
  done

  log "Updating nameservers in $RESOLV_CONF (sudo needed)"
  sudo cp "$temp_file" "$RESOLV_CONF"
  rm -f "$temp_file"
}

restart_services() {
  log "Restarting systemd-resolved (sudo needed)..."
  sudo systemctl restart systemd-resolved

  log "Restarting dnsmasq (sudo needed)..."
  sudo systemctl restart dnsmasq
}

check_ddns() {
  log "Calling DDNS update endpoint..."
  local response http_status body
  response=$(curl --silent --show-error --location --get --write-out "HTTPSTATUS:%{http_code}" "$UPDATE_URL")
  http_status="${response##*HTTPSTATUS:}"
  body="${response%HTTPSTATUS:*}"
  body="$(echo "$body" | tr -d '\r\n[:space:]')"

  if [ "$http_status" != "200" ]; then
    notify_failure "DDNS update failed (HTTP $http_status). Response: $body"
    exit 1
  fi

  if [[ ! "$body" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    notify_failure "DDNS update returned unexpected content: $body"
    exit 1
  fi

  notify_success "DDNS updated successfully. IP: $body"
}

main() {
  require_cmd curl
  ensure_nameserver
  restart_services
  check_ddns
}

main "$@"
