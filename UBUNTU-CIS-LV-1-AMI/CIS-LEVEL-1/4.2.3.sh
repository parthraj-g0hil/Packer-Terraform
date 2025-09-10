#!/bin/bash
set -euo pipefail

echo "========================================"
echo "Vulnerability: 4.2.3 Ensure UFW service is enabled"
echo "========================================"

# Step 1: Unmask UFW service
echo "[*] Unmasking ufw.service..."
systemctl unmask ufw.service || true

# Step 2: Allow SSH before enabling UFW
echo "[*] Allowing SSH (22/tcp) before enabling UFW..."
ufw allow proto tcp from any to any port 22 comment 'Allow SSH for remote access'

# Step 3: Enable and start UFW service
echo "[*] Enabling and starting ufw.service..."
systemctl --now enable ufw.service

# Step 4: Enable UFW (force to avoid SSH warning prompt during packer build)
echo "[*] Enabling UFW..."
ufw --force enable

# Step 5: Verify status
echo "[*] Verifying UFW service and rules..."
systemctl status ufw.service --no-pager
ufw status verbose

echo "========================================"
echo "CIS-compliant UFW service configuration applied."
echo "========================================"
