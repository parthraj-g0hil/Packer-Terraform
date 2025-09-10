#!/bin/bash
set -euo pipefail

SERVICE="systemd-timesyncd"

# Step 1: Stop and mask chrony if installed
if systemctl list-unit-files | grep -q '^chrony\.service'; then
    systemctl stop chrony >/dev/null 2>&1 || true
    systemctl mask chrony >/dev/null 2>&1 || true
fi

# Step 2: Install systemd-timesyncd if missing
if ! systemctl list-unit-files | grep -qw "$SERVICE.service"; then
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y systemd-timesyncd >/dev/null 2>&1
fi

# Step 3: Ensure systemd-timesyncd starts after network-online.target
mkdir -p /etc/systemd/system/"$SERVICE".service.d
cat <<EOF >/etc/systemd/system/"$SERVICE".service.d/override.conf
[Unit]
After=network-online.target
Wants=network-online.target
EOF

# Reload systemd to pick up override
systemctl daemon-reexec

# Step 4: Unmask, enable, and start systemd-timesyncd
systemctl unmask "$SERVICE.service" >/dev/null 2>&1 || true
systemctl enable "$SERVICE.service" >/dev/null 2>&1
systemctl start "$SERVICE.service" >/dev/null 2>&1

# Step 5: Optional: verify status silently
enabled=$(systemctl is-enabled "$SERVICE.service" 2>/dev/null)
active=$(systemctl is-active "$SERVICE.service" 2>/dev/null)
sync_status=$(timedatectl show -p NTPSynchronized --value 2>/dev/null)

if [[ "$enabled" != "enabled" || "$active" != "active" ]]; then
    echo "ERROR: systemd-timesyncd is not running correctly" >&2
    exit 1
fi

# NTP synchronization check is optional, no output
if [[ "$sync_status" != "yes" ]]; then
    # just silently continue, network might be needed
    true
fi
