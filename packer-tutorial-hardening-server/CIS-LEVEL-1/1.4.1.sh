#!/bin/bash
# 1.4.1 Ensure bootloader password is set

echo "========================================"
echo "Vulnerability: 1.4.1 Ensure bootloader password is set"
echo "========================================"

# Step 1: Check if bootloader password is configured
echo "[*] Checking for bootloader password (password_pbkdf2)..."
grep -qi "password_pbkdf2" /etc/grub.d/* /boot/grub/grub.cfg 2>/dev/null
boot_password_set=$?

if [[ $boot_password_set -eq 0 ]]; then
    echo "✅ Bootloader password is already set."
else
    echo "❌ Bootloader password not found. Running update-grub..."
    sudo update-grub >/dev/null 2>&1

    echo "[*] Re-checking grub configuration..."
    grep -qi "password_pbkdf2" /boot/grub/grub.cfg 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "✅ Bootloader password now set."
    else
        echo "❌ Bootloader password still missing."
    fi
fi

echo "========================================"
echo
