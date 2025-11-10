#!/usr/bin/env bash
set -euo pipefail

HYPRCTL_BIN=${HYPRCTL_BIN:-hyprctl}
DOCK_BIN=${DOCK_BIN:-nwg-dock-hyprland}
read -r -a DOCK_ARGS <<< "${NWG_DOCK_ARGS:--d}"

log() {
  printf '[nwg-dock-launch] %s\n' "$1" >&2
}

get_outputs() {
  "$HYPRCTL_BIN" monitors -j | python - <<'PY'
import json, sys
try:
    data = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(1)
print("\n".join(mon["name"] for mon in data if mon.get("name")))
PY
}

if ! mapfile -t outputs < <(get_outputs); then
  log "Unable to query Hyprland outputs via hyprctl"
  exit 1
fi
if [[ ${#outputs[@]} -eq 0 ]]; then
  log "No Hyprland outputs detected; nwg-dock-hyprland not started"
  exit 0
fi

log "Restarting existing dock instances"
dock_process=$(basename "$DOCK_BIN")
pkill -x "$dock_process" >/dev/null 2>&1 || true

for output in "${outputs[@]}"; do
  log "Launching dock for ${output}"
  "$DOCK_BIN" -m "${DOCK_ARGS[@]}" -o "${output}" &
done

exit 0
