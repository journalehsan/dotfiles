#!/usr/bin/env bash

# Bootstrap dotfiles on a new device
# Usage: ./setup-new-device.sh <device-name>

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}Usage: $0 <device-name>${NC}"
    echo -e "${YELLOW}Example: $0 desktop-4k${NC}"
    echo -e "${YELLOW}Example: $0 work-laptop${NC}"
    exit 1
fi

DEVICE_NAME="$1"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}=== Setting up dotfiles for new device: $DEVICE_NAME ===${NC}"
echo

# Check if we're in a git repo
if [ ! -d "$DOTFILES_DIR/.git" ]; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Check if branch already exists
if git show-ref --verify --quiet refs/heads/"$DEVICE_NAME"; then
    echo -e "${YELLOW}Branch '$DEVICE_NAME' already exists!${NC}"
    echo -e "${BLUE}Switching to existing branch...${NC}"
    git checkout "$DEVICE_NAME"
else
    echo -e "${BLUE}Step 1: Creating new branch from main...${NC}"
    git checkout main
    git pull origin main
    git checkout -b "$DEVICE_NAME"
    echo -e "${GREEN}✓ Branch '$DEVICE_NAME' created${NC}"
    echo
fi

# Create device-specific notes file
echo -e "${BLUE}Step 2: Creating device documentation...${NC}"
DEVICE_DOC="DEVICE_${DEVICE_NAME^^}.md"

cat > "$DEVICE_DOC" << EOF
# Device: $DEVICE_NAME

## Hardware Specs

- **Model:** (Add your device model)
- **CPU:** (Add CPU info)
- **GPU:** (Add GPU info)
- **RAM:** (Add RAM info)
- **Display:** (Add display resolution and refresh rate)

## Device-Specific Settings

### Display Configuration

\`\`\`bash
# Monitor resolution and scaling
# File: .config/hypr/monitors.conf
# Example: monitor=eDP-1,2880x1800@90,0x0,1.5
\`\`\`

### Power Management

- Battery optimizations: (yes/no)
- TLP profile: (balanced/performance/battery)

### Input Devices

- Touchpad: (yes/no)
- Drawing tablet: (yes/no)
- External keyboard: (model)

## Custom Tweaks

### Applied on $(date +%Y-%m-%d)

- (Document your device-specific customizations here)

## Known Issues

- (Document any device-specific issues or workarounds)

## Installation Date

- Initial setup: $(date +%Y-%m-%d)
- Last updated: $(date +%Y-%m-%d)
EOF

git add "$DEVICE_DOC"
git commit -m "Add device documentation for $DEVICE_NAME"
echo -e "${GREEN}✓ Device documentation created: $DEVICE_DOC${NC}"
echo

# Run install script
echo -e "${BLUE}Step 3: Installing dotfiles...${NC}"
./install.sh

echo
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Edit ${GREEN}$DEVICE_DOC${NC} with your device specs"
echo -e "2. Customize device-specific configs:"
echo -e "   - ${YELLOW}.config/hypr/monitors.conf${NC} (display resolution/scaling)"
echo -e "   - ${YELLOW}.config/hypr/envs.conf${NC} (environment variables)"
echo -e "   - ${YELLOW}.config/waybar/config.jsonc${NC} (bar modules)"
echo -e "3. Commit your changes:"
echo -e "   ${GREEN}git add .${NC}"
echo -e "   ${GREEN}git commit -m '$DEVICE_NAME: Initial device-specific configuration'${NC}"
echo -e "4. Push to remote:"
echo -e "   ${GREEN}git push origin $DEVICE_NAME -u${NC}"
echo
echo -e "${YELLOW}Tip: Keep universal improvements separate and cherry-pick them to 'main'${NC}"
echo -e "${YELLOW}See BRANCH_STRATEGY.md for workflow details${NC}"
