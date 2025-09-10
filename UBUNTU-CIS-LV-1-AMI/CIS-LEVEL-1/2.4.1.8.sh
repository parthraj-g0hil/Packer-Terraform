#!/bin/bash
# 2.4.1.8 Ensure crontab is restricted to authorized users

echo "========================================"
echo "Vulnerability: 2.4.1.8 Ensure crontab is restricted to authorized users"
echo "========================================"

CRON_ALLOW="/etc/cron.allow"

# Step 1: Check if cron is installed and crontab restrictions (internal check)
echo "[*] Checking cron installation and crontab restrictions..."
if dpkg -l cron >/dev/null 2>&1; then
    cron_installed=true
else
    cron_installed=false
fi

# Step 2: Remediate
if $cron_installed; then
    echo "[*] Restricting crontab access to root only..."
    sudo bash -c "echo 'root' > $CRON_ALLOW" >/dev/null 2>&1

    # Set correct permissions
    sudo chmod 640 "$CRON_ALLOW" >/dev/null 2>&1

    # Set ownership based on crontab group
    if getent group crontab >/dev/null 2>&1; then
        sudo chown root:crontab "$CRON_ALLOW" >/dev/null 2>&1
    else
        sudo chown root:root "$CRON_ALLOW" >/dev/null 2>&1
    fi
else
    echo "❌ Cron is not installed. Install cron manually."
fi

# Step 3: Verify internally
current_owner=$(stat -c "%U:%G" "$CRON_ALLOW" 2>/dev/null || echo "missing")
current_perm=$(stat -c "%a" "$CRON_ALLOW" 2>/dev/null || echo "000")
if [[ "$current_owner" =~ root && "$current_perm" == "640" ]]; then
    echo "✅ Crontab restricted to authorized users successfully."
else
    echo "❌ Crontab permissions or ownership not correct. Check manually."
fi

echo "========================================"
echo
