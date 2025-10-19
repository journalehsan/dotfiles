#!/bin/bash

# Network speed script for waybar
# Gets download/upload speeds and formats them with icons
#
# Add Wifi support by changing the INTERFACE detection logic if needed
INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n 1)

#   Check if interface is found and coneected
#   If not, output no network icon and exit
# Check if interface is found
#
if ! ip link show "$INTERFACE" &>/dev/null; then
    echo '{"text":"󰌙 No Net","tooltip":"No network interface found"}'
    exit 0
fi
# default to wlan0 if INTERFACE is empty
if [ -z "$INTERFACE" ]; then
    INTERFACE="wlan0"
fi
# Check if interface is up
STATE=$(cat /sys/class/net/$INTERFACE/operstate 2>/dev/null ||
echo "down")
if [ "$STATE" != "up" ]; then
    echo '{"text":"󰌙 No Net","tooltip":"Network interface is down"}'
    exit 0
fi
# Check if INTERFACE is empty
if [ -z "$INTERFACE" ]; then
    echo '{"text":"󰌙 No Net","tooltip":"No network interface found"}'
    exit 0
fi

# File to store previous stats
STATS_FILE="/tmp/waybar_net_stats_$INTERFACE"

# Get current stats
RX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes 2>/dev/null || echo 0)
TX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes 2>/dev/null || echo 0)
CURRENT_TIME=$(date +%s)

# Read previous stats
if [ -f "$STATS_FILE" ]; then
    read PREV_RX PREV_TX PREV_TIME < "$STATS_FILE"
    # Validate that we read the data correctly
    if [ -z "$PREV_RX" ] || [ -z "$PREV_TX" ] || [ -z "$PREV_TIME" ]; then
        PREV_RX=$RX_BYTES
        PREV_TX=$TX_BYTES
        PREV_TIME=$CURRENT_TIME
    fi
else
    # First run - initialize with current values
    PREV_RX=$RX_BYTES
    PREV_TX=$TX_BYTES
    PREV_TIME=$CURRENT_TIME
    echo "$RX_BYTES $TX_BYTES $CURRENT_TIME" > "$STATS_FILE"
    # Exit early on first run to establish baseline
    echo '{"text":"󰇚 -- 󰕒 --","tooltip":"Network Speed\\nInterface: $INTERFACE\\nInitializing..."}'
    exit 0
fi

# Calculate speeds
TIME_DIFF=$((CURRENT_TIME - PREV_TIME))
if [ $TIME_DIFF -gt 1 ] && [ $TIME_DIFF -lt 60 ]; then
    RX_SPEED=$(( (RX_BYTES - PREV_RX) / TIME_DIFF ))
    TX_SPEED=$(( (TX_BYTES - PREV_TX) / TIME_DIFF ))
    
    # Ensure speeds are not negative (can happen if interface resets)
    if [ $RX_SPEED -lt 0 ]; then RX_SPEED=0; fi
    if [ $TX_SPEED -lt 0 ]; then TX_SPEED=0; fi
else
    # Not enough time has passed or too much time - show 0
    RX_SPEED=0
    TX_SPEED=0
fi

# Store current stats for next run
echo "$RX_BYTES $TX_BYTES $CURRENT_TIME" > "$STATS_FILE"

# Format speeds
format_bytes() {
    local bytes=$1
    if [ $bytes -lt 1024 ]; then
        echo "${bytes}B/s"
    elif [ $bytes -lt 1048576 ]; then
        echo "$((bytes / 1024))K/s"
    elif [ $bytes -lt 1073741824 ]; then
        echo "$((bytes / 1048576))M/s"
    else
        echo "$((bytes / 1073741824))G/s"
    fi
}

DOWN_FORMATTED=$(format_bytes $RX_SPEED)
UP_FORMATTED=$(format_bytes $TX_SPEED)

# Create JSON output
echo "{\"text\":\"󰇚 ${DOWN_FORMATTED} 󰕒 ${UP_FORMATTED}\",\"tooltip\":\"Network Speed\\nInterface: $INTERFACE\\nDownload: $DOWN_FORMATTED\\nUpload: $UP_FORMATTED\"}"
