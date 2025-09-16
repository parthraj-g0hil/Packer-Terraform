#!/bin/bash
set -euo pipefail

echo "========================================"
echo "CIS Remediation: 6.1.4.1 Ensure access to all logfiles is configured"
echo "========================================"

# Step 1: Fix sysstat logs if they exist
if [ -d /var/log/sysstat ]; then
    sudo chmod 640 /var/log/sysstat/* 2>/dev/null || true
fi

# Step 2: Fix apt logs if they exist
for log in /var/log/apt/history.log /var/log/apt/term.log; do
    [ -f "$log" ] && sudo chmod 640 "$log" 2>/dev/null
done

if [ -d /var/log/unattended-upgrades ]; then
    sudo chmod 640 /var/log/unattended-upgrades/* 2>/dev/null || true
fi

# Step 3: Fix special logs
for log in /var/log/wtmp /var/log/btmp /var/log/lastlog; do
    [ -f "$log" ] && sudo chown root:utmp "$log" && sudo chmod 600 "$log"
done

echo "✅ Log file ownership and permissions applied successfully."
echo "========================================"
