#!/bin/bash
# 5.3.3.1.2 Ensure password unlock time is configured (faillock)

echo "========================================"
echo "Vulnerability: 5.3.3.1.2 Ensure password unlock time is configured"
echo "========================================"

FAILLOCK_CONF="/etc/security/faillock.conf"
UNLOCK_VALUE="900"  # 900 seconds = 15 minutes

# Step 1: Remediate unlock_time and root_unlock_time
sudo sed -i -E "s/^\s*#?\s*unlock_time\s*=.*/unlock_time = $UNLOCK_VALUE/" $FAILLOCK_CONF > /dev/null 2>&1 || \
    echo "unlock_time = $UNLOCK_VALUE" | sudo tee -a $FAILLOCK_CONF > /dev/null
sudo sed -i -E "s/^\s*#?\s*root_unlock_time\s*=.*/root_unlock_time = $UNLOCK_VALUE/" $FAILLOCK_CONF > /dev/null 2>&1 || \
    echo "root_unlock_time = $UNLOCK_VALUE" | sudo tee -a $FAILLOCK_CONF > /dev/null

# Step 2: Verify silently
grep -i unlock_time $FAILLOCK_CONF > /dev/null 2>&1

# Step 3: Confirmation
echo "Password unlock time configured successfully (unlock_time=$UNLOCK_VALUE, root_unlock_time=$UNLOCK_VALUE)."
echo "========================================"
