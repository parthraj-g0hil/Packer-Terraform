#!/bin/bash
# 1.4.1 Ensure bootloader password is set (verify + update)

set -euo pipefail

GRUB_CFG="/boot/grub/grub.cfg"

echo "========================================"
echo "CIS Check: 1.4.1 Bootloader password verification"
echo "========================================"

# Step 1: Verify password_pbkdf2 exists in /etc/grub.d/40_custom
if grep -qi "password_pbkdf2" /etc/grub.d/40_custom; then
    echo "[*] Bootloader password found in /etc/grub.d/40_custom"
else
    echo "❌ Warning: No bootloader password found in /etc/grub.d/40_custom"
fi

# Step 2: Update grub configuration
echo "[*] Updating GRUB configuration..."
sudo update-grub >/dev/null 2>&1

# Step 3: Verify password_pbkdf2 is in the generated grub.cfg
if grep -qi "password_pbkdf2" "$GRUB_CFG"; then
    echo "✅ Bootloader password is active in grub.cfg"
else
    echo "❌ Bootloader password not applied in grub.cfg"
fi

echo "========================================"
