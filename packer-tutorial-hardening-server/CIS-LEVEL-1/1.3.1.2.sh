#!/bin/bash
# 1.3.1.2 Ensure AppArmor is enabled in the bootloader configuration

echo "========================================"
echo "Vulnerability: 1.3.1.2 Ensure AppArmor is enabled in the bootloader configuration"
echo "========================================"

GRUB_CFG="/etc/default/grub"
REQUIRED_PARAMS="apparmor=1 security=apparmor"

# Step 1: Check if AppArmor is already enabled in the current boot
echo "[*] Checking current kernel boot parameters..."
if grep -q "$REQUIRED_PARAMS" /proc/cmdline; then
    echo "[*] AppArmor is already enabled at boot."
else
    echo "[!] AppArmor is NOT enabled at boot. Remediating..."

    # Step 2: Backup GRUB config
    sudo cp "$GRUB_CFG" "$GRUB_CFG.bak_$(date +%F_%T)"

    # Step 3: Add AppArmor boot parameters if missing
    if grep -q "^GRUB_CMDLINE_LINUX=" "$GRUB_CFG"; then
        sudo sed -i "/^GRUB_CMDLINE_LINUX=/ s/\"\$/ $REQUIRED_PARAMS\"/" "$GRUB_CFG"
    else
        echo "GRUB_CMDLINE_LINUX=\"$REQUIRED_PARAMS\"" | sudo tee -a "$GRUB_CFG" > /dev/null
    fi

    # Step 4: Update GRUB
    sudo update-grub

    echo "[*] AppArmor boot parameters added. They will take effect on next reboot."
fi

# Step 3: Verify the change in GRUB config
echo "[*] Verifying GRUB configuration..."
grep -i "GRUB_CMDLINE_LINUX" "$GRUB_CFG"

echo "========================================"
echo "Script completed. AppArmor will be active on next boot."
echo
