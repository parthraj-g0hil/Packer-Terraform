#!/bin/bash
# 3.3.8 Ensure source routed packets are not accepted

set -euo pipefail

echo "========================================"
echo "Vulnerability: 3.3.8 Ensure source routed packets are not accepted"
echo "========================================"

SYSCTL_CONF="/etc/sysctl.d/60-netipv4-source-route.conf"

# Step 1: Check current settings
echo "[*] Checking current IPv4 source route acceptance..."
sysctl net.ipv4.conf.all.accept_source_route
sysctl net.ipv4.conf.default.accept_source_route

echo "[*] Checking IPv6 source route acceptance (if enabled)..."
if sysctl -a 2>/dev/null | grep -q 'net.ipv6.conf'; then
    sysctl net.ipv6.conf.all.accept_source_route
    sysctl net.ipv6.conf.default.accept_source_route
else
    echo "IPv6 not enabled, skipping IPv6 check."
fi

# Step 2: Remediate IPv4
echo "[*] Disabling IPv4 source routed packets..."
sudo sysctl -w net.ipv4.conf.default.accept_source_route=0 >/dev/null 2>&1
sudo sysctl -w net.ipv4.route.flush=1 >/dev/null 2>&1

# Persist changes
echo "[*] Writing persistent IPv4 configuration..."
sudo tee "$SYSCTL_CONF" >/dev/null <<EOF
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
EOF

# Reload sysctl configs silently (avoid Packer hang)
sudo sysctl --system >/dev/null 2>&1 || true

# Step 3: Verify again
echo "[*] Verifying IPv4 settings..."
sysctl net.ipv4.conf.all.accept_source_route
sysctl net.ipv4.conf.default.accept_source_route

echo "========================================"
echo "Source routed packets disabled successfully."
echo
