#!/usr/bin/env bash

# Waybar Jalali module wrapper
# Prefer the `jdate` CLI for accuracy; fallback to python script

set -euo pipefail

sun_icon="☀️"

# Read toggle state set by jalali-toggle.sh
STATE_FILE="$HOME/.cache/waybar/jalali_format"
fmt_state="default"
if [[ -f "$STATE_FILE" ]]; then
    # shellcheck disable=SC2002
    fmt_state=$(cat "$STATE_FILE" 2>/dev/null || echo default)
fi

to_persian_digits() {
    # Translate ASCII digits to Persian digits using sed
    sed 'y/0123456789/۰۱۲۳۴۵۶۷۸۹/'
}

if command -v jdate >/dev/null 2>&1; then
    # Use jdate for accurate Persian calendar
    # Zero-padded month/day to match e.g. 1404/08/06
    j_date=$(jdate +%Y/%m/%d 2>/dev/null)
    # Human-readable for tooltip (weekday likely Persian)
    j_human=$(jdate +"%A %Y/%m/%d" 2>/dev/null || echo "$j_date")
    now_time=$(date +"%H:%M")

    if [[ "$fmt_state" == "alt" ]]; then
        j_date_pd=$(printf "%s" "$j_date" | to_persian_digits)
        tooltip=$(printf "%s\nتقویم: شمسی (جلالی)\nGregorian: %s\nClick to open time.ir" "$j_human" "$(date +%Y-%m-%d)")
        printf '{"text":"%s %s (%s)","tooltip":"%s","class":"jalali-calendar"}\n' "$sun_icon" "$j_date_pd" "شمسی" "$tooltip"
    else
        printf '{"text":"%s %s","tooltip":"Jalali Date: %s\nTime: %s\nClick to open time.ir","class":"jalali-calendar"}\n' "$sun_icon" "$j_date" "$j_human" "$now_time"
    fi
else
	# Fallback to Python script using uv environment
	if command -v uv >/dev/null 2>&1; then
		# Ensure persiantools is available in the ephemeral env
		uv run --with persiantools ~/.config/waybar/scripts/jalali-date-simple.py
	else
		~/.config/waybar/scripts/jalali-date-simple.py
	fi
fi
