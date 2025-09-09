#!/bin/bash
set -euo pipefail

echo "========================================"
echo "Vulnerability: 4.2.4 Ensure UFW loopback traffic is configured"
echo "========================================"

# Step 1: Reset and enable UFW
echo "[*] Resetting UFW..."
ufw --force reset
echo "[*] Enabling UFW..."
ufw --force enable

# Step 2: Configure loopback rules
echo "[*] Allowing loopback traffic..."
ufw allow in on lo comment 'Allow inbound loopback'
ufw allow out on lo comment 'Allow outbound loopback'

echo "[*] Denying loopback traffic from non-loopback interfaces..."
ufw deny in from 127.0.0.0/8 comment 'Deny IPv4 loopback from external'
ufw deny in from ::1 comment 'Deny IPv6 loopback from external'

# Step 3: Always allow SSH so we don’t lock ourselves out
echo "[*] Allowing SSH..."
ufw allow in 22/tcp comment 'Allow SSH'

# Step 4: Reload and verify
echo "[*] Reloading UFW..."
ufw reload

echo "[*] Final UFW status:"
ufw status verbose

echo "========================================"
echo "CIS-compliant UFW loopback configuration applied."
echo "========================================"
