#!/usr/bin/env python3

import datetime
import json
import os


def gregorian_to_jalali_simple(gy: int, gm: int, gd: int) -> str:
    """Approximate Gregorian->Jalali conversion kept as a fallback."""
    base_date = datetime.date(622, 3, 22)
    current_date = datetime.date(gy, gm, gd)
    days_diff = (current_date - base_date).days

    jalali_year = 1 + days_diff // 365
    remaining_days = days_diff % 365
    leap_adjustment = jalali_year // 4
    remaining_days -= leap_adjustment

    if remaining_days < 0:
        jalali_year -= 1
        remaining_days += 365
        if jalali_year % 4 == 3:
            remaining_days += 1

    jalali_months = [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29]
    if jalali_year % 4 == 3:
        jalali_months[11] = 30

    month = 1
    day = remaining_days
    for days_in_month in jalali_months:
        if day > days_in_month:
            day -= days_in_month
            month += 1
        else:
            break

    return f"{jalali_year:04d}/{month:02d}/{day:02d}"


def get_jalali_today() -> tuple[str, str]:
    """Return today's Jalali date as YYYY/MM/DD using persiantools if available."""
    try:
        from persiantools.jdatetime import JalaliDate

        j = JalaliDate.today()
        date_str = f"{j.year:04d}/{j.month:02d}/{j.day:02d}"
        weekday_fa = j.strftime("%A")
        return date_str, weekday_fa
    except Exception:
        now = datetime.datetime.now()
        date_str = gregorian_to_jalali_simple(now.year, now.month, now.day)
        # Fallback weekday (Gregorian) in English to avoid wrong info
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
