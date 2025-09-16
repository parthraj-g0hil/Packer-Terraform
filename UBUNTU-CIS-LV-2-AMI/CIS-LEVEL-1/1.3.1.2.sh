#!/bin/bash
set -euo pipefail

echo "========================================"
echo "🔧 Fixing GRUB to enable AppArmor (keep exactly one line)"
echo "========================================"

GRUB_FILE="/etc/default/grub"
PARAMS="audit_backlog_limit=8192 audit=1 apparmor=1 security=apparmor"

# Step 1: Backup grub file
cp "$GRUB_FILE" "$GRUB_FILE.bak_$(date +%F_%T)"

# Step 2: Remove all existing GRUB_CMDLINE_LINUX lines
sed -i '/^GRUB_CMDLINE_LINUX=/d' "$GRUB_FILE"

# Step 3: Insert the required line *after* GRUB_DISTRIBUTOR
sed -i "/^GRUB_DISTRIBUTOR=.*/a GRUB_CMDLINE_LINUX=\"$PARAMS\"" "$GRUB_FILE"

# Step 4: Update grub
update-grub >/dev/null 2>&1

# Step 5: Verify
if grep -q "^GRUB_CMDLINE_LINUX=\"$PARAMS\"" "$GRUB_FILE"; then
    echo "✅ GRUB fixed: only one clean GRUB_CMDLINE_LINUX entry exists"
else
    echo "❌ Failed to fix GRUB_CMDLINE_LINUX" >&2
    exit 1
fi

echo "========================================"
echo "🔧 Installing AppArmor tools"
echo "========================================"
apt-get update -qq >/dev/null 2>&1
apt-get install -y apparmor apparmor-utils >/dev/null 2>&1

echo "✅ AppArmor packages installed"

echo "========================================"
echo "ℹ️ Reboot required"
echo "========================================"
echo "Please reboot the system to apply changes."
