#!/bin/bash
# 5.3.3.3.3 Ensure pam_pwhistory includes use_authtok

echo "========================================"
echo "Vulnerability: 5.3.3.3.3 Ensure pam_pwhistory includes use_authtok"
echo "========================================"

PAM_CONFIG_DIR="/usr/share/pam-configs"
PAM_PROFILE="$PAM_CONFIG_DIR/pwhistory"
REMEMBER_VALUE=24

# Step 1: Create or update the pwhistory profile with enforce_for_root and use_authtok
echo "[*] Ensuring pam_pwhistory includes use_authtok..."
sudo tee "$PAM_PROFILE" > /dev/null <<EOF
Name: pwhistory
Default: yes
Priority: 1024
Password-Type: Primary
Password: requisite pam_pwhistory.so remember=$REMEMBER_VALUE enforce_for_root try_first_pass use_authtok
EOF

# Step 2: Enable the profile using pam-auth-update
echo "[*] Enabling pam_pwhistory profile..."
sudo pam-auth-update --enable pwhistory --quiet

# Step 3: Verify configuration in common-password
echo "[*] Verifying common-password for pam_pwhistory..."
grep -E "pam_pwhistory\.so.*remember=$REMEMBER_VALUE.*enforce_for_root.*use_authtok" /etc/pam.d/common-password \
  || echo "[!] pam_pwhistory not correctly configured with use_authtok in common-password"

echo "========================================"
echo "pam_pwhistory configured with use_authtok successfully."
echo "========================================"
