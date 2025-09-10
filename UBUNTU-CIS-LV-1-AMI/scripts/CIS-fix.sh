#!/bin/bash
set -euo pipefail

LOGFILE="/root/cis_fix_timesync_acct.log"
exec > >(tee -a "$LOGFILE") 2>&1
exec 2>&1

echo "🔧 Starting CIS Fix Script..."

### 1. Enable Process Accounting
echo "📌 Enabling process accounting..."
if ! dpkg -s acct >/dev/null 2>&1; then
    apt install -y acct
fi
systemctl enable --now acct
echo "✅ Process accounting enabled."

### 2. Install & Enable Timesync
echo "📌 Configuring time synchronization..."
if ! dpkg -s systemd-timesyncd >/dev/null 2>&1; then
    apt install -y systemd-timesyncd
fi
systemctl enable --now systemd-timesyncd
timedatectl timesync-status || true
echo "✅ Time synchronization enabled."

echo "🎉 CIS Fix Completed Successfully."
