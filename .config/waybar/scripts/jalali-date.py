#!/usr/bin/env python3

import datetime
import json

def gregorian_to_jalali(gy, gm, gd):
    """Convert Gregorian date to Jalali date"""
    g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    
    if gm > 2:
        gy2 = gy + 1
    else:
        gy2 = gy
    
    days = 365 * gy2 + (gy2 + 3) // 4
    days -= (gy2 + 99) // 100
    days += (gy2 + 399) // 400
    days += g_d_m[gm - 1] + gd
    
    jy = 621 + (4 * days + 1) // 1461
    days -= (1461 * (jy - 621)) // 4
    
    if days < 0:
        jy -= 1
        days += 1461
    
    leap = jy % 4
    if leap == 0:
        leap = 1
    else:
        leap = 0
    
    if days < 79:
        jm = 1
        jd = days + 22
    elif days < 150:
        jm = 2
        jd = days - 78
    elif days < 221:
        jm = 3
        jd = days - 149
    elif days < 292:
        jm = 4
        jd = days - 220
    elif days < 363:
        jm = 5
        jd = days - 291
    elif days < 434:
        jm = 6
        jd = days - 362
    elif days < 505:
        jm = 7
        jd = days - 433
    elif days < 576:
        jm = 8
        jd = days - 504
    elif days < 647:
        jm = 9
        jd = days - 575
    elif days < 718:
        jm = 10
        jd = days - 646
    elif days < 789:
        jm = 11
        jd = days - 717
    else:
        jm = 12
        jd = days - 788
    
    return f"{jy}/{jm}/{jd}"

# Get current date
now = datetime.datetime.now()
jalali_date = gregorian_to_jalali(now.year, now.month, now.day)
current_time = now.strftime("%H:%M")

# Create JSON output for Waybar
output = {
    "text": f"☀️ {jalali_date}",
    "tooltip": f"Jalali Date: {jalali_date}\nTime: {current_time}\nClick to open time.ir",
    "class": "jalali-calendar"
}

print(json.dumps(output))
