#!/usr/bin/env bash

# Waybar Jalali module wrapper
# Prefer the `jdate` CLI for accuracy; fallback to python script

set -euo pipefail

sun_icon="☀️"

if command -v jdate >/dev/null 2>&1; then
	# Use jdate for accurate Persian calendar
	# Zero-padded month/day to match e.g. 1404/08/06
	j_date=$(jdate +%Y/%m/%d 2>/dev/null)
	# Human-readable for tooltip
	j_human=$(jdate +"%A %Y/%m/%d" 2>/dev/null || echo "$j_date")
	now_time=$(date +"%H:%M")
	printf '{"text":"%s %s","tooltip":"Jalali Date: %s\nTime: %s\nClick to open time.ir","class":"jalali-calendar"}\n' "$sun_icon" "$j_date" "$j_human" "$now_time"
else
	# Fallback to Python script using uv environment
	if command -v uv >/dev/null 2>&1; then
		# Ensure persiantools is available in the ephemeral env
		uv run --with persiantools ~/.config/waybar/scripts/jalali-date-simple.py
	else
		~/.config/waybar/scripts/jalali-date-simple.py
	fi
fi
