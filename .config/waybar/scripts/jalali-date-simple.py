#!/usr/bin/env python3

import datetime
import json
import os


def get_jalali_today() -> tuple[str, str]:
    """Return today's Jalali date as YYYY/MM/DD using jdatetime."""
    try:
        import jdatetime
        j = jdatetime.date.today()
        date_str = f"{j.year:04d}/{j.month:02d}/{j.day:02d}"
        weekday_name = jdatetime.datetime.now().strftime("%A")
        return date_str, weekday_name
    except ImportError:
        # Fallback if jdatetime is not available
        now = datetime.datetime.now()
        date_str = now.strftime("%Y/%m/%d")
        weekday_fa = now.strftime("%A")
        return date_str, weekday_fa


def to_persian_digits(s: str) -> str:
    return s.translate(str.maketrans("0123456789", "۰۱۲۳۴۵۶۷۸۹"))


def shamsi_icon() -> str:
    h = datetime.datetime.now().hour
    return "☀️" if 6 <= h < 18 else "🌙"


now = datetime.datetime.now()
j_date, weekday_fa = get_jalali_today()
current_time = now.strftime("%H:%M")

# Read toggle state (default or alt)
state_file = os.path.expanduser("~/.cache/waybar/jalali_format")
fmt_state = "default"
try:
    if os.path.isfile(state_file):
        with open(state_file, "r", encoding="utf-8") as f:
            fmt_state = (f.read().strip() or "default")
except Exception:
    fmt_state = "default"

icon = shamsi_icon()

if fmt_state == "alt":
    # Alternate format: Persian weekday + Persian numerals + explicit Shamsi label
    j_date_persian_digits = to_persian_digits(j_date)
    text = f"{icon} {j_date_persian_digits} (شمسی)"
    tooltip = (
        f"{weekday_fa} - {j_date_persian_digits}\n"
        f"تقویم: شمسی (جلالی)\n"
        f"Gregorian: {now.strftime('%Y-%m-%d')}\n"
        f"Click to open time.ir"
    )
else:
    # Default format: ASCII digits YYYY/MM/DD
    text = f"{icon} {j_date}"
    tooltip = (
        f"Jalali Date: {j_date}\n"
        f"Time: {current_time}\n"
        f"Click to open time.ir"
    )

output = {
    "text": text,
    "tooltip": tooltip,
    "class": "jalali-calendar",
}

print(json.dumps(output))
