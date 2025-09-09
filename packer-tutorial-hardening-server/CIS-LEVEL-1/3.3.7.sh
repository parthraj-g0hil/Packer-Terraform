#!/bin/bash
# 3.3.7 Ensure reverse path filtering is enabled

set -euo pipefail

echo "========================================"
echo "Vulnerability: 3.3.7 Ensure reverse path filtering is enabled"
echo "========================================"

SYSCTL_CONF="/etc/sysctl.d/60-netipv4-rpfilter.conf"
MAIN_IFACE="enX0"   # <--- update this to your real interface name if different

# Step 1: Apply active settings
echo "[*] Applying runtime rp_filter settings..."
sudo sysctl -w net.ipv4.conf.all.rp_filter=1 >/dev/null 2>&1
sudo sysctl -w net.ipv4.conf.default.rp_filter=1 >/dev/null 2>&1
sudo sysctl -w net.ipv4.conf.$MAIN_IFACE.rp_filter=1 >/dev/null 2>&1
sudo sysctl -w net.ipv4.route.flush=1 >/dev/null 2>&1

# Step 2: Persist in sysctl.d
echo "[*] Writing persistent configuration..."
sudo tee "$SYSCTL_CONF" >/dev/null <<EOF
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.$MAIN_IFACE.rp_filter = 1
EOF

# Step 3: Reload sysctl settings silently
sudo sysctl --system >/dev/null 2>&1 || true

# Step 4: Verify
echo "[*] Verifying rp_filter settings..."
sysctl net.ipv4.conf.all.rp_filter
sysctl net.ipv4.conf.default.rp_filter
sysctl net.ipv4.conf.$MAIN_IFACE.rp_filter

echo "========================================"
echo "Reverse path filtering enabled successfully."
echo
