#!/bin/bash
set -euo pipefail

echo "========================================"
echo "CIS PAM Configuration: Password History Enforcement"
echo "========================================"

PAM_CONFIG_DIR="/usr/share/pam-configs"
PAM_PROFILE="$PAM_CONFIG_DIR/pwhistory"
REMEMBER_VALUE=24

# Step 1: Create or update the pwhistory profile
echo "[*] Ensuring pam_pwhistory profile exists and includes root enforcement..."
sudo tee "$PAM_PROFILE" > /dev/null <<EOF
Name: pwhistory
Default: yes
Priority: 1024
Password-Type: Primary
Password: requisite pam_pwhistory.so remember=$REMEMBER_VALUE enforce_for_root try_first_pass use_authtok
EOF

# Step 2: Enable the profile with pam-auth-update (quiet mode for automation)
echo "[*] Enabling pam_pwhistory profile..."
sudo pam-auth-update --enable pwhistory --quiet

# Step 3: Verify configuration in common-password
echo "[*] Verifying common-password for pam_pwhistory..."
if grep -E "pam_pwhistory\.so.*remember=$REMEMBER_VALUE.*enforce_for_root.*use_authtok" /etc/pam.d/common-password >/dev/null 2>&1; then
    echo "✅ pam_pwhistory correctly configured for password history and root enforcement."
else
    echo "[!] pam_pwhistory not correctly configured in common-password"
fi

echo "========================================"
echo "CIS PAM password history configuration applied successfully."
echo "========================================"
