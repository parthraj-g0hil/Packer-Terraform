#!/bin/bash
# 2.3.2.2 Ensure systemd-timesyncd is enabled and running

echo "========================================"
echo "Vulnerability: 2.3.2.2 Ensure systemd-timesyncd is enabled and running"
echo "========================================"

SERVICE="systemd-timesyncd"

# Step 0: Check if the service exists
if ! systemctl list-unit-files >/dev/null 2>&1 | grep -qw "$SERVICE.service"; then
    echo "⚠️ $SERVICE not installed. Installing..."
#    sudo apt-get update -y >/dev/null 2>&1
    sudo apt-get install -y systemd-timesyncd >/dev/null 2>&1
fi

# Step 1: Unmask, enable, start
echo "[*] Unmasking $SERVICE (if masked)..."
sudo systemctl unmask "$SERVICE.service" >/dev/null 2>&1

echo "[*] Enabling and starting $SERVICE..."
sudo systemctl enable --now "$SERVICE.service" >/dev/null 2>&1

# Step 2: Verify
enabled=$(systemctl is-enabled "$SERVICE.service" 2>/dev/null)
active=$(systemctl is-active "$SERVICE.service" 2>/dev/null)
sync_status=$(timedatectl show -p NTPSynchronized --value 2>/dev/null)

if [[ "$enabled" == "enabled" && "$active" == "active" && "$sync_status" == "yes" ]]; then
    echo "✅ $SERVICE is installed, enabled, running, and time is synchronized."
else
    echo "❌ Remediation failed. Check manually or verify network access for NTP."
fi

echo "========================================"
echo
