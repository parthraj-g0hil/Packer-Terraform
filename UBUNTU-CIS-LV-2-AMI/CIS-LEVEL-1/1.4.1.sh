#!/bin/bash

# Script to remediate CIS 1.4.1: Ensure bootloader password is set
# Sets GRUB superuser 'user-admin' with password 'Emc@123' and updates GRUB configuration
# Non-interactive for Packer builds

set -e  # Exit on any error

# Set non-interactive frontend for debconf to prevent prompts
export DEBIAN_FRONTEND=noninteractive

# Install grub2-common if not already installed (required for grub-mkpasswd-pbkdf2)
if ! dpkg -l | grep -q '^ii\s*grub2-common'; then
    echo "Installing grub2-common..."
    apt-get update -y
    apt-get install -y --no-install-recommends grub2-common
fi

# Define GRUB superuser and password
GRUB_USER="admin"
GRUB_PASSWORD="Emc@123"

# Generate PBKDF2 password hash non-interactively
echo "Generating GRUB password hash for user '$GRUB_USER'..."
GRUB_PWD_HASH=$(echo -e "$GRUB_PASSWORD\n$GRUB_PASSWORD" | grub-mkpasswd-pbkdf2 --iteration-count=600000 --salt=64 | grep "PBKDF2 hash" | awk '{print $NF}')

# Create custom GRUB configuration file
CUSTOM_GRUB_FILE="/etc/grub.d/40_custom"
echo "Creating custom GRUB configuration at $CUSTOM_GRUB_FILE..."
cat << EOF > $CUSTOM_GRUB_FILE
#!/bin/sh
exec tail -n +2 \$0
set superusers="$GRUB_USER"
password_pbkdf2 $GRUB_USER $GRUB_PWD_HASH
EOF

# Set permissions on the custom GRUB file
chmod 600 $CUSTOM_GRUB_FILE

# Optionally allow unrestricted booting (uncomment the following block if you want to boot without password prompt)
# echo "Modifying /etc/grub.d/10_linux to allow unrestricted booting..."
# sed -i 's/CLASS="--class gnu-linux --class gnu --class os"/CLASS="--class gnu-linux --class gnu --class os --unrestricted"/' /etc/grub.d/10_linux

# Update GRUB configuration
echo "Updating GRUB configuration..."
update-grub

echo "Remediation complete: GRUB bootloader password is set for user '$GRUB_USER'."