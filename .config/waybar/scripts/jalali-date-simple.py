#!/usr/bin/env python3

import datetime
import json


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


def get_jalali_today() -> str:
    """Return today's Jalali date as YYYY/MM/DD using persiantools if available."""
    try:
        from persiantools.jdatetime import JalaliDate

        j = JalaliDate.today()
        return f"{j.year:04d}/{j.month:02d}/{j.day:02d}"
    except Exception:
        now = datetime.datetime.now()
        return gregorian_to_jalali_simple(now.year, now.month, now.day)


now = datetime.datetime.now()
jalali_date_str = get_jalali_today()
current_time = now.strftime("%H:%M")

output = {
    "text": f"☀️ {jalali_date_str}",
    "tooltip": f"Jalali Date: {jalali_date_str}\nTime: {current_time}\nClick to open time.ir",
    "class": "jalali-calendar",
}

print(json.dumps(output))
