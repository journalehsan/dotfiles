#!/usr/bin/env bash

set -euo pipefail

STATE_DIR="$HOME/.cache/waybar"
STATE_FILE="$STATE_DIR/jalali_format"
SIGNAL_NUM=25   # Must match the module's "signal" in config.jsonc

mkdir -p "$STATE_DIR"
current="default"
if [[ -f "$STATE_FILE" ]]; then
	current=$(cat "$STATE_FILE" || echo default)
fi

if [[ "$current" == "default" ]]; then
	echo "alt" > "$STATE_FILE"
else
	echo "default" > "$STATE_FILE"
fi

# Refresh waybar custom module listening on this realtime signal
pkill -RTMIN+$SIGNAL_NUM waybar >/dev/null 2>&1 || true
