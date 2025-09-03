#!/bin/bash
set -euo pipefail

echo "🔐 Securing GRUB with password (edit access only, no boot-time lock)"

# Predefined GRUB credentials
GRUB_USER="admin"
GRUB_PASSWORD="EMI-linux09"

# Generate PBKDF2 hash (non-interactive)
GRUB_HASH=$(echo -e "${GRUB_PASSWORD}\n${GRUB_PASSWORD}" | grub-mkpasswd-pbkdf2 | grep "PBKDF2 hash" | awk '{print $NF}')
echo "✅ Generated GRUB password hash."

# Files
CUSTOM_FILE="/etc/grub.d/40_custom"
CUSTOM_BACKUP="${CUSTOM_FILE}.bak.$(date +%F-%T)"
DEFAULTS_FILE="/etc/default/grub"
DEFAULTS_BACKUP="${DEFAULTS_FILE}.bak.$(date +%F-%T)"

# Backup before changes
cp "$CUSTOM_FILE" "$CUSTOM_BACKUP"
echo "🧾 Backup of 40_custom saved: $CUSTOM_BACKUP"
cp "$DEFAULTS_FILE" "$DEFAULTS_BACKUP"
echo "🧾 Backup of grub defaults saved: $DEFAULTS_BACKUP"

# Add GRUB superuser if not already present
if ! grep -q "password_pbkdf2 $GRUB_USER" "$CUSTOM_FILE"; then
    cat <<EOF >> "$CUSTOM_FILE"

# GRUB password protection
set superuser="$GRUB_USER"
password_pbkdf2 $GRUB_USER $GRUB_HASH
EOF
    echo "✅ Added GRUB superuser configuration."
else
    echo "⚠️ GRUB superuser config already exists in $CUSTOM_FILE"
fi

# Ensure required GRUB options in defaults
grep -q "^GRUB_TIMEOUT_STYLE=" "$DEFAULTS_FILE" \
  && sed -i "s/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/" "$DEFAULTS_FILE" \
  || echo "GRUB_TIMEOUT_STYLE=menu" >> "$DEFAULTS_FILE"

grep -q "^GRUB_ENABLE_CRYPTODISK=" "$DEFAULTS_FILE" \
  && sed -i "s/^GRUB_ENABLE_CRYPTODISK=.*/GRUB_ENABLE_CRYPTODISK=y/" "$DEFAULTS_FILE" \
  || echo "GRUB_ENABLE_CRYPTODISK=y" >> "$DEFAULTS_FILE"

# Apply changes
echo "🔁 Updating GRUB configuration..."
update-grub

echo "✅ GRUB password protection enabled for user '$GRUB_USER'."
echo "🚀 Normal boots won't ask for a password, but editing boot entries or GRUB CLI will."
