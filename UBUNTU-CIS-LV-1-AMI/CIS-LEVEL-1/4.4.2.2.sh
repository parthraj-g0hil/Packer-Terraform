#!/bin/bash
set -euo pipefail

echo "========================================"
echo "Vulnerability: 4.4.2.2 Ensure iptables loopback traffic is configured"
echo "========================================"

# Step 1: Install iptables and persistence package
echo "[*] Installing iptables and iptables-persistent..."
export DEBIAN_FRONTEND=noninteractive
#apt-get update -y
apt-get install -y iptables iptables-persistent

# Step 2: Flush existing rules
echo "[*] Flushing existing iptables rules..."
iptables -F

# Step 3: Configure loopback traffic rules
echo "[*] Configuring loopback traffic rules..."
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -s 127.0.0.0/8 -j DROP

# Step 4: Save rules for persistence
echo "[*] Saving iptables rules..."
iptables-save > /etc/iptables/rules.v4

# Step 5: Verify
echo "[*] Verifying applied iptables rules..."
iptables -L -v

echo "========================================"
echo "CIS-compliant iptables loopback configuration applied."
echo "========================================"
