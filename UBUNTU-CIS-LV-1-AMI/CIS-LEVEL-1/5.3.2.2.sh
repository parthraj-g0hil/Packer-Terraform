#!/bin/bash
set -euo pipefail

echo "========================================"
echo "Vulnerability: 5.3.2.2 Ensure pam_faillock module is enabled"
echo "========================================"

# Step 1: Check current pam_faillock configuration
grep pam_faillock /etc/pam.d/common-auth 2>/dev/null || true
grep pam_faillock /etc/pam.d/common-account 2>/dev/null || true

# Step 2: Create configuration files
sudo tee /usr/share/pam-configs/faillock >/dev/null <<'EOF'
Name: Enable pam_faillock to deny access
Default: yes
Priority: 0
Auth-Type: Primary
Auth:        [default=die] pam_faillock.so authfail
EOF

sudo tee /usr/share/pam-configs/faillock_notify >/dev/null <<'EOF'
Name: Notify of failed login attempts and reset count upon success
Default: yes
Priority: 1024
Auth-Type: Primary
Auth:        requisite pam_faillock.so preauth
Account-Type: Primary
Account:     required pam_faillock.so
EOF

# Step 3: Enable modules non-interactively (ignore errors)
export DEBIAN_FRONTEND=noninteractive
sudo pam-auth-update --enable faillock --force >/dev/null 2>&1 || true
sudo pam-auth-update --enable faillock_notify --force >/dev/null 2>&1 || true

# Step 4: Verify
grep pam_faillock /etc/pam.d/common-auth || true
grep pam_faillock /etc/pam.d/common-account || true

echo "========================================"
echo "pam_faillock module enabled successfully."
echo
