#!/bin/bash

echo "=== Current /etc/fstab ==="
cat /etc/fstab

echo ""
echo "=== Proposed changes ==="
echo ""

# Create temp file
TEMP_FSTAB=$(mktemp)
cp /etc/fstab "$TEMP_FSTAB"

# Apply same transformations
sed -i 's/compress=zstd:3/compress=zstd:1/g' "$TEMP_FSTAB"
sed -i 's/rw,relatime/rw,noatime/g' "$TEMP_FSTAB"

if ! grep -q "commit=120" "$TEMP_FSTAB"; then
    sed -i '/btrfs.*subvol=\/@[^h]/ s/subvol=\/@/commit=120,discard=async,subvol=\/@/' "$TEMP_FSTAB"
    sed -i '/btrfs.*subvol=\/@home/ s/subvol=\/@home/commit=120,discard=async,subvol=\/@home/' "$TEMP_FSTAB"
    sed -i '/btrfs.*subvol=\/@pkg/ s/subvol=\/@pkg/commit=120,discard=async,subvol=\/@pkg/' "$TEMP_FSTAB"
    sed -i '/btrfs.*subvol=\/@log/ s/subvol=\/@log/commit=120,discard=async,subvol=\/@log/' "$TEMP_FSTAB"
fi

if ! grep -q "tmpfs.*/tmp" "$TEMP_FSTAB"; then
    echo "" >> "$TEMP_FSTAB"
    echo "# tmpfs for performance" >> "$TEMP_FSTAB"
    echo "tmpfs   /tmp        tmpfs   defaults,noatime,mode=1777,size=1G   0 0" >> "$TEMP_FSTAB"
fi

if ! grep -q "tmpfs.*/var/tmp" "$TEMP_FSTAB"; then
    echo "tmpfs   /var/tmp    tmpfs   defaults,noatime,mode=1777,size=512M 0 0" >> "$TEMP_FSTAB"
fi

cat "$TEMP_FSTAB"

echo ""
echo "=== Diff (old -> new) ==="
diff --color=always -u /etc/fstab "$TEMP_FSTAB" || true

rm "$TEMP_FSTAB"

echo ""
echo "To apply these changes, run: ~/dotfiles/scripts/optimize-lowend-storage.sh"
