#!/bin/bash
set -e

FSTAB="/etc/fstab"
BACKUP="/etc/fstab.bak.$(date +%F_%H-%M-%S)"
ENTRY="tmpfs   /dev/shm   tmpfs   rw,nosuid,nodev,noexec,size=512M   0  0"

# Backup fstab
cp "$FSTAB" "$BACKUP"

# Add entry if not exists
grep -q "/dev/shm" "$FSTAB" || echo "$ENTRY" >> "$FSTAB"

# Remount /dev/shm
mount -o remount /dev/shm 2>/dev/null || mount /dev/shm 2>/dev/null

# Reload systemd daemon
systemctl daemon-reexec >/dev/null 2>&1

# Verify (only errors shown)
mount | grep -q "/dev/shm" || echo "[ERROR] /dev/shm not mounted properly!"
df -h | grep -q "/dev/shm" || echo "[ERROR] df does not show /dev/shm!"
