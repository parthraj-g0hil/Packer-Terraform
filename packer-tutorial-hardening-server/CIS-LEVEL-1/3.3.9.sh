#!/bin/bash
# 3.3.9 Ensure suspicious packets are logged

echo "========================================"
echo "Vulnerability: 3.3.9 Ensure suspicious packets are logged"
echo "========================================"

SYSCTL_CONF="/etc/sysctl.d/60-netipv4_sysctl.conf"

# Step 1: Check current values
echo "[*] Checking current net.ipv4.conf.*.log_martians settings..."
sysctl net.ipv4.conf.all.log_martians
sysctl net.ipv4.conf.default.log_martians

# Step 2: Remediate
echo "[*] Enabling logging of suspicious packets..."
sudo sysctl -w net.ipv4.conf.all.log_martians=1
sudo sysctl -w net.ipv4.conf.default.log_martians=1
sudo sysctl -w net.ipv4.route.flush=1

# Persist settings
printf '%s\n' "net.ipv4.conf.all.log_martians = 1" \
"net.ipv4.conf.default.log_martians = 1" | sudo tee "$SYSCTL_CONF" > /dev/null

# Apply sysctl settings immediately
sudo sysctl --system

# Step 3: Verify again
echo "[*] Verifying net.ipv4.conf.*.log_martians settings..."
sysctl net.ipv4.conf.all.log_martians
sysctl net.ipv4.conf.default.log_martians

echo "========================================"
echo "Suspicious packet logging configured successfully."
echo
