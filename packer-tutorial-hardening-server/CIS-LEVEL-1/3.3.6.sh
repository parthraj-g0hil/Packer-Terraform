#!/bin/bash
set -euo pipefail

echo "========================================"
echo "CIS: Disable secure ICMP redirects (3.3.6)"
echo "========================================"

SYSCTL_CONF="/etc/sysctl.d/60-netipv4-secure-redirects.conf"

# Step 1: Write sysctl config
sudo tee "$SYSCTL_CONF" >/dev/null <<EOF
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
EOF

# Step 2: Apply settings immediately (silent)
sudo sysctl -w net.ipv4.conf.all.secure_redirects=0 >/dev/null 2>&1
sudo sysctl -w net.ipv4.conf.default.secure_redirects=0 >/dev/null 2>&1

# Step 3: Apply to all interfaces
for iface_path in /proc/sys/net/ipv4/conf/*; do
    iface=$(basename "$iface_path")
    sudo sysctl -w net.ipv4.conf.$iface.secure_redirects=0 >/dev/null 2>&1 || true
done

# Step 4: Reload sysctl settings silently
sudo sysctl --system >/dev/null 2>&1 || true

# Step 5: Optional verification (silent)
grep -H secure_redirects /proc/sys/net/ipv4/conf/* 2>/dev/null || true

echo "========================================"
echo "Secure ICMP redirects disabled successfully."
echo
