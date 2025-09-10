#!/bin/bash
set -euo pipefail

echo "========================================"
echo "Disabling IPv4 packet redirects (CIS 3.3.2)"
echo "========================================"

# Step 1: Apply sysctl config file
sudo tee /etc/sysctl.d/60-disable-redirects.conf >/dev/null <<EOF
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
EOF

# Step 2: Apply settings immediately (silently)
sudo sysctl -w net.ipv4.conf.all.send_redirects=0 >/dev/null 2>&1
sudo sysctl -w net.ipv4.conf.default.send_redirects=0 >/dev/null 2>&1
sudo sysctl -w net.ipv4.route.flush=1 >/dev/null 2>&1

# Step 3: Apply to all interfaces
for iface_path in /proc/sys/net/ipv4/conf/*; do
    iface=$(basename "$iface_path")
    sudo sysctl -w net.ipv4.conf.$iface.send_redirects=0 >/dev/null 2>&1 || true
done

# Step 4: Optional verification (silent)
grep -H send_redirects /proc/sys/net/ipv4/conf/* 2>/dev/null || true

echo "========================================"
echo "Packet redirect sending disabled successfully."
echo
