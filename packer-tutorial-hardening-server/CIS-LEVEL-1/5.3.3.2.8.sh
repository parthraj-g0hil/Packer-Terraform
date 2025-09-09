#!/bin/bash
# 5.3.3.2.8 Ensure password quality is enforced for the root user

echo "========================================"
echo "Vulnerability: 5.3.3.2.8 Ensure password quality is enforced for the root user"
echo "========================================"

ROOT_PWCONF_DIR="/etc/security/pwquality.conf.d"
ROOT_PWCONF_FILE="$ROOT_PWCONF_DIR/50-pwroot.conf"

# Step 1: Check if enforce_for_root is set (internal check)
echo "[*] Checking if password quality is enforced for root..."
enforce_root=$(grep -r "enforce_for_root" /etc/security/pwquality.conf /etc/security/pwquality.conf.d/ 2>/dev/null || true)

# Step 2: Remediate if needed
if [[ -z "$enforce_root" ]]; then
    echo "[*] Enforcing password quality for root..."
    sudo mkdir -p "$ROOT_PWCONF_DIR" >/dev/null 2>&1
    echo "enforce_for_root" | sudo tee "$ROOT_PWCONF_FILE" >/dev/null
else
    echo "✅ Password quality already enforced for root."
fi

# Step 3: Verify internally
enforce_root_updated=$(grep -r "enforce_for_root" /etc/security/pwquality.conf /etc/security/pwquality.conf.d/ 2>/dev/null || true)
if [[ -n "$enforce_root_updated" ]]; then
    echo "✅ Password quality enforcement for root user configured successfully."
else
    echo "❌ Remediation failed. Check manually."
fi

echo "========================================"
echo
