#!/bin/bash
# 1.1.1.9 Ensure usb-storage kernel module is not available

echo "========================================"
echo "Vulnerability: 1.1.1.9 Ensure usb-storage kernel module is not available"
echo "========================================"

MOD_CONF="/etc/modprobe.d/usb-storage.conf"

# Step 1: Check if usb-storage module is loaded
echo "[*] Checking if usb-storage module is loaded..."
if lsmod | grep -q usb_storage; then
    module_loaded=true
else
    module_loaded=false
fi

# Step 2: Remediate
echo "[*] Disabling usb-storage module..."
sudo tee "$MOD_CONF" >/dev/null <<EOF
install usb-storage /bin/false
blacklist usb-storage
EOF

# Optionally unload the module immediately if it is loaded
if $module_loaded; then
    echo "[*] Unloading usb-storage module..."
    sudo modprobe -r usb_storage >/dev/null 2>&1
fi

# Step 3: Verify internally
if lsmod | grep -q usb_storage; then
    echo "❌ usb-storage module is still loaded. Check manually."
else
    echo "✅ usb-storage module disabled successfully."
fi

echo "========================================"
echo
