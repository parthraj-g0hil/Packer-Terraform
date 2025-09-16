#!/bin/bash
set -euo pipefail

echo "========================================"
echo "Vulnerability: 5.3.2.4 Ensure pam_pwhistory module is enabled"
echo "========================================"

# Step 1: Check if pam_pwhistory is already configured
if grep -q "pam_pwhistory.so" /etc/pam.d/common-password 2>/dev/null; then
    echo "✅ pam_pwhistory module already configured in common-password."
else
    # Step 2: Add pam_pwhistory line to common-password
    echo "password requisite pam_pwhistory.so remember=24 enforce_for_root try_first_pass use_authtok" | sudo tee -a /etc/pam.d/common-password >/dev/null
    echo "✅ pam_pwhistory module enabled and configured successfully."
fi

echo "========================================"
