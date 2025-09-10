#!/bin/bash
set -euxo pipefail

# CIS 5.3.3.1.1 - Ensure password failed attempts lockout is configured
# Packer-safe version: avoids pam-auth-update to prevent hangs

FAILLOCK_CONF="/etc/security/faillock.conf"
DENY_VALUE="5"

# Step 1: Ensure faillock.conf exists
sudo touch "$FAILLOCK_CONF"

# Step 2: Remove any old or commented deny lines
sudo sed -i -E '/^\s*#?\s*deny\s*=.*/d' "$FAILLOCK_CONF"

# Step 3: Add correct deny setting
echo "deny = $DENY_VALUE" | sudo tee -a "$FAILLOCK_CONF" >/dev/null

# Step 4: Verify
updated_deny=$(grep -i '^\s*deny\s*=' "$FAILLOCK_CONF" | awk -F= '{print $2}' | tr -d ' ' || true)

if [[ "$updated_deny" == "$DENY_VALUE" ]]; then
    echo "✅ Password failed attempts lockout configured successfully (deny=$DENY_VALUE)."
else
    echo "❌ Remediation failed. Check manually."
fi
