#!/bin/bash
set -euxo pipefail

# CIS 5.3.3.1.1 - Ensure password failed attempts lockout is configured
# Packer-safe version: avoids pam-auth-update to prevent hangs

FAILLOCK_CONF="/etc/security/faillock.conf"
DENY_VALUE="5"

echo "========================================"
echo "Vulnerability: 5.3.3.1.1 Ensure password failed attempts lockout is configured (Packer-safe)"
echo "========================================"

# Step 1: Ensure faillock.conf exists
sudo touch "$FAILLOCK_CONF"

# Step 2: Set deny = 5
if grep -qE '^\s*deny\s*=' "$FAILLOCK_CONF"; then
    sudo sed -i -E "s/^\s*deny\s*=.*/deny = $DENY_VALUE/" "$FAILLOCK_CONF"
else
    echo "deny = $DENY_VALUE" | sudo tee -a "$FAILLOCK_CONF" >/dev/null
fi

# Step 3: Verify internally (without interactive PAM commands)
updated_deny=$(grep -i deny "$FAILLOCK_CONF" 2>/dev/null | awk -F= '{print $2}' | tr -d ' ' || true)

if [[ "$updated_deny" == "$DENY_VALUE" ]]; then
    echo "✅ Password failed attempts lockout configured successfully (deny=$DENY_VALUE)."
else
    echo "❌ Remediation failed. Check manually."
fi

echo "========================================"
