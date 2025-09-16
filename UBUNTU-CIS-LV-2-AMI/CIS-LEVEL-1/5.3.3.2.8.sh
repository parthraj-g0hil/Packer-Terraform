#!/bin/bash
# 5.3.3.2.8 Ensure password quality is enforced for the root user

echo "========================================"
echo "Vulnerability: 5.3.3.2.8 Ensure password quality is enforced for the root user"
echo "========================================"

ROOT_PWCONF_DIR="/etc/security/pwquality.conf.d"
ROOT_PWCONF_FILE="$ROOT_PWCONF_DIR/50-pwroot.conf"

# Step 1: Ensure pwquality.d directory exists
sudo mkdir -p "$ROOT_PWCONF_DIR"

# Step 2: Remove any old or commented enforce_for_root lines (cleanup)
sudo sed -i -E '/^\s*#?\s*enforce_for_root\s*$/d' /etc/security/pwquality.conf 2>/dev/null || true
sudo sed -i -E '/^\s*#?\s*enforce_for_root\s*$/d' "$ROOT_PWCONF_FILE" 2>/dev/null || true

# Step 3: Add enforce_for_root explicitly
echo "enforce_for_root" | sudo tee "$ROOT_PWCONF_FILE" >/dev/null

# Step 4: Verify
if grep -q '^[[:space:]]*enforce_for_root' "$ROOT_PWCONF_FILE"; then
    echo "✅ Password quality enforcement for root user is correctly configured."
else
    echo "❌ Remediation failed. Please check manually."
fi

echo "========================================"
