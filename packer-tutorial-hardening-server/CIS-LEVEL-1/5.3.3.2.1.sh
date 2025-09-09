#!/bin/bash

echo "========================================"
echo "Vulnerability: 5.3.3.2.1 Ensure difok is set for password changes"
echo "========================================"

# Step 1: Check current difok setting
echo "[*] Checking current difok settings..."
difok_check=$(grep -i difok /etc/security/pwquality.conf.d/* 2>/dev/null | awk -F= '{print $2}' | tr -d ' ')

if [[ "$difok_check" == "2" ]]; then
    echo "✅ difok is already set to 2"
else
    echo "❌ difok is not set correctly. Applying remediation..."

    # Step 2: Remediate
    # Ensure drop-in directory exists
    sudo mkdir -p /etc/security/pwquality.conf.d/ >/dev/null 2>&1

    # Set difok to 2
    echo "difok = 2" | sudo tee /etc/security/pwquality.conf.d/50-pwdifok.conf >/dev/null

    # Comment out any previous difok in main config
    sudo sed -i 's/^\s*difok\s*=/# &/' /etc/security/pwquality.conf >/dev/null 2>&1

    # Step 3: Verify again (internal check, not printing raw grep)
    difok_check_after=$(grep -i difok /etc/security/pwquality.conf.d/* 2>/dev/null | awk -F= '{print $2}' | tr -d ' ')
    if [[ "$difok_check_after" == "2" ]]; then
        echo "✅ Remediation applied: difok = 2"
    else
        echo "❌ Remediation failed. Check manually."
    fi
fi

echo "========================================"
echo
