#!/usr/bin/env bash

# WPA2-Enterprise Setup Script for systemd-networkd
# Configures PEAP + MSCHAPv2 authentication without certificates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SSID="${1:-staff}"
IDENTITY="${2:-ehsan.tork@mtnirancell.ir}"
PASSWORD="${3:-Trk@#14059021100733}"
INTERFACE=""

echo -e "${GREEN}=== WPA2-Enterprise Setup for systemd-networkd ===${NC}\n"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Detect wireless interface
echo "Detecting wireless interface..."
INTERFACE=$(ip link | grep -E '^\d+: w' | awk -F': ' '{print $2}' | head -n1)

if [ -z "$INTERFACE" ]; then
    echo -e "${RED}No wireless interface found!${NC}"
    exit 1
fi

echo -e "${GREEN}Found wireless interface: $INTERFACE${NC}\n"

# Stop conflicting services
echo "Stopping conflicting services..."
systemctl stop iwd 2>/dev/null || true
systemctl disable iwd 2>/dev/null || true
systemctl stop wpa_supplicant 2>/dev/null || true

# Create wpa_supplicant configuration
WPA_CONF="/etc/wpa_supplicant/wpa_supplicant-${INTERFACE}.conf"
echo "Creating wpa_supplicant configuration at $WPA_CONF..."

cat > "$WPA_CONF" <<EOF
ctrl_interface=/run/wpa_supplicant
update_config=1

network={
    ssid="$SSID"
    key_mgmt=WPA-EAP
    eap=PEAP
    identity="$IDENTITY"
    password="$PASSWORD"
    phase2="auth=MSCHAPV2"
    # No certificate validation
}
EOF

# Secure the configuration file
chmod 600 "$WPA_CONF"
echo -e "${GREEN}Configuration file secured (600 permissions)${NC}"

# Create systemd-networkd configuration
NETWORK_CONF="/etc/systemd/network/25-wireless.network"
echo "Creating systemd-networkd configuration at $NETWORK_CONF..."

cat > "$NETWORK_CONF" <<EOF
[Match]
Name=$INTERFACE

[Network]
DHCP=yes
IgnoreCarrierLoss=3s

[DHCP]
RouteMetric=20
UseDNS=yes
EOF

# Enable and start services
echo -e "\nEnabling services..."
systemctl enable wpa_supplicant@${INTERFACE}
systemctl enable systemd-networkd
systemctl enable systemd-resolved

echo "Starting services..."
systemctl start wpa_supplicant@${INTERFACE}
systemctl restart systemd-networkd
systemctl start systemd-resolved

# Wait a moment for connection
echo -e "\n${YELLOW}Waiting for connection...${NC}"
sleep 5

# Check connection status
echo -e "\n=== Connection Status ==="
wpa_cli -i "$INTERFACE" status | grep -E "wpa_state|ip_address|ssid" || echo "Could not get status"

echo -e "\n=== IP Address ==="
ip addr show "$INTERFACE" | grep "inet " || echo "No IP address assigned yet"

echo -e "\n${GREEN}=== Setup Complete ===${NC}"
echo -e "Interface: ${GREEN}$INTERFACE${NC}"
echo -e "SSID: ${GREEN}$SSID${NC}"
echo -e "Identity: ${GREEN}$IDENTITY${NC}"
echo -e "\nConfiguration files:"
echo -e "  - $WPA_CONF"
echo -e "  - $NETWORK_CONF"
echo -e "\nTo check status: ${YELLOW}wpa_cli -i $INTERFACE status${NC}"
echo -e "To monitor logs: ${YELLOW}journalctl -u wpa_supplicant@${INTERFACE} -f${NC}"
