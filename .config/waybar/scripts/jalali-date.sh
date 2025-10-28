#!/bin/bash

# Jalali Calendar Script for Waybar
# Converts Gregorian date to Jalali/Persian date using accurate algorithm

# Function to convert Gregorian to Jalali
gregorian_to_jalali() {
    local gy=$1
    local gm=$2
    local gd=$3
    
    local jy jm jd
    local leap
    
    # Calculate leap year for Gregorian
    if [ $((gy % 4)) -eq 0 ] && ([ $((gy % 100)) -ne 0 ] || [ $((gy % 400)) -eq 0 ]); then
        leap=1
    else
        leap=0
    fi
    
    # Days in each Gregorian month
    local g_days_in_month=(31 28 31 30 31 30 31 31 30 31 30 31)
    if [ $leap -eq 1 ]; then
        g_days_in_month[1]=29
    fi
    
    # Calculate total days since March 1, 1 AD
    local total_days=0
    
    # Add days from previous years
    local y
    for ((y=1; y<gy; y++)); do
        if [ $((y % 4)) -eq 0 ] && ([ $((y % 100)) -ne 0 ] || [ $((y % 400)) -eq 0 ]); then
            total_days=$((total_days + 366))
        else
            total_days=$((total_days + 365))
        fi
    done
    
    # Add days from current year
    local i
    for ((i=0; i<gm-1; i++)); do
        total_days=$((total_days + g_days_in_month[i]))
    done
    total_days=$((total_days + gd))
    
    # Convert to Jalali
    # March 22, 622 AD = Farvardin 1, 1 AH
    local jalali_epoch_days=226899  # Days from 1 AD to March 22, 622 AD
    
    local jalali_total_days=$((total_days - jalali_epoch_days))
    
    # Calculate Jalali year
    jy=$((jalali_total_days / 365))
    local remaining_days=$((jalali_total_days % 365))
    
    # Adjust for leap years in Jalali calendar
    local leap_years=$((jy / 4))
    remaining_days=$((remaining_days - leap_years))
    
    if [ $remaining_days -lt 0 ]; then
        jy=$((jy - 1))
        remaining_days=$((remaining_days + 365))
        if [ $((jy % 4)) -eq 3 ]; then
            remaining_days=$((remaining_days + 1))
        fi
    fi
    
    # Determine Jalali month and day
    local j_days_in_month=(31 31 31 31 31 31 30 30 30 30 30 29)
    if [ $((jy % 4)) -eq 3 ]; then
        j_days_in_month[11]=30  # Leap year in Jalali calendar
    fi
    
    jm=1
    jd=$remaining_days
    
    for ((i=0; i<12; i++)); do
        if [ $jd -gt ${j_days_in_month[i]} ]; then
            jd=$((jd - j_days_in_month[i]))
            jm=$((jm + 1))
        else
            break
        fi
    done
    
    echo "$jy/$jm/$jd"
}

# Get current date
current_date=$(date +"%Y %m %d")
read -r year month day <<< "$current_date"

# Convert to Jalali
jalali_date=$(gregorian_to_jalali $year $month $day)

# Get current time
current_time=$(date +"%H:%M")

# Create JSON output for Waybar
cat << EOF
{
    "text": "☀️ $jalali_date",
    "tooltip": "Jalali Date: $jalali_date\nTime: $current_time\nClick to open time.ir",
    "class": "jalali-calendar"
}
EOF
