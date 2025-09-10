#!/bin/bash
set -euo pipefail

echo "========================================"
echo "Vulnerability: 5.3.3.2.2 Ensure minimum password length is configured"
echo "========================================"

# Step 1: Check current minlen settings silently
grep -i minlen /etc/security/pwquality.conf 2>/dev/null || true
grep -r -i minlen /etc/security/pwquality.conf.d/ 2>/dev/null || true
grep pam_pwquality /etc/pam.d/common-password 2>/dev/null || true

# Step 2: Remediate
sudo mkdir -p /etc/security/pwquality.conf.d/
echo "minlen = 14" | sudo tee /etc/security/pwquality.conf.d/50-pwlength.conf >/dev/null

# Comment out previous minlen in main config if exists
sudo sed -i 's/^\s*minlen\s*=/# &/' /etc/security/pwquality.conf || true

# Step 3: Verify again
grep -i minlen /etc/security/pwquality.conf.d/* 2>/dev/null || true

echo "========================================"
echo "Minimum password length configured successfully."
echo
