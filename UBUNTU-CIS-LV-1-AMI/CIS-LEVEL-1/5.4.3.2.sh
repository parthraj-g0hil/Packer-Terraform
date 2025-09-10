#!/bin/bash
# 5.4.3.2 Ensure default user shell timeout is configured

echo "========================================"
echo "Vulnerability: 5.4.3.2 Ensure default user shell timeout is configured"
echo "========================================"

TIMEOUT_FILE="/etc/profile.d/timeout.sh"
TIMEOUT_VALUE=900

# Step 1: Check current TMOUT configuration
echo "[*] Checking existing TMOUT configuration..."
[ -f "$TIMEOUT_FILE" ] && ls -l "$TIMEOUT_FILE"
echo "Current TMOUT value: $TMOUT"

# Step 2: Remediate
echo "[*] Setting default shell timeout to $TIMEOUT_VALUE seconds..."
sudo tee "$TIMEOUT_FILE" > /dev/null <<EOF
TMOUT=$TIMEOUT_VALUE
readonly TMOUT
export TMOUT
EOF

# Apply immediately
source "$TIMEOUT_FILE"

# Step 3: Verify again
echo "[*] Verifying TMOUT configuration..."
cat "$TIMEOUT_FILE"
echo "Current TMOUT value after remediation: $TMOUT"

echo "========================================"
echo "Default shell timeout configured successfully."
echo
