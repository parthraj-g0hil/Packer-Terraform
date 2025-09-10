#!/bin/bash
# 5.3.3.2.4 Ensure password same consecutive characters is configured

echo "========================================"
echo "Vulnerability: 5.3.3.2.4 Ensure password same consecutive characters is configured"
echo "========================================"

PWQUALITY_DIR="/etc/security/pwquality.conf.d/"
PWQUALITY_FILE="${PWQUALITY_DIR}50-pwrepeat.conf"
MAXREPEAT_VALUE="3"

# Step 1: Check current maxrepeat settings (internal check only)
echo "[*] Checking current maxrepeat settings..."
current_maxrepeat=$(grep -ri maxrepeat "$PWQUALITY_DIR" 2>/dev/null | awk -F= '{print $2}' | tr -d ' ' || true)

# Step 2: Remediate if needed
if [[ "$current_maxrepeat" != "$MAXREPEAT_VALUE" ]]; then
    echo "[*] Applying remediation: setting maxrepeat = $MAXREPEAT_VALUE"
    sudo mkdir -p "$PWQUALITY_DIR" >/dev/null 2>&1
    echo "maxrepeat = $MAXREPEAT_VALUE" | sudo tee "$PWQUALITY_FILE" >/dev/null
else
    echo "✅ maxrepeat is already set to $MAXREPEAT_VALUE"
fi

# Step 3: Verify internally
updated_maxrepeat=$(grep -ri maxrepeat "$PWQUALITY_DIR" 2>/dev/null | awk -F= '{print $2}' | tr -d ' ' || true)
if [[ "$updated_maxrepeat" == "$MAXREPEAT_VALUE" ]]; then
    echo "✅ Password maxrepeat configured successfully."
else
    echo "❌ Remediation failed. Check manually."
fi

echo "========================================"
echo
