#!/bin/bash

# Script to remediate CIS 5.2.7: Ensure access to the su command is restricted
# Creates a group and configures PAM to restrict su access to that group
# Adds 'ssm-user' and 'ubuntu' to the group (note: this deviates from CIS 5.2.7's empty group recommendation)
# Non-interactive for Packer builds

set -e  # Exit on any error

# Set non-interactive frontend for debconf to prevent prompts
export DEBIAN_FRONTEND=noninteractive

# Create a group for su restriction
GROUP_NAME="sugroup"
if ! getent group "$GROUP_NAME" > /dev/null; then
    echo "Creating group '$GROUP_NAME'..."
    groupadd "$GROUP_NAME"
else
    echo "Group '$GROUP_NAME' already exists."
fi

# Add users to the group if they exist
echo "Adding users 'ssm-user' and 'ubuntu' to '$GROUP_NAME'..."
if id "ssm-user" &>/dev/null; then
    usermod -aG "$GROUP_NAME" ssm-user
    echo "Added 'ssm-user' to '$GROUP_NAME'."
else
    echo "User 'ssm-user' does not exist; skipping."
fi

if id "ubuntu" &>/dev/null; then
    usermod -aG "$GROUP_NAME" ubuntu
    echo "Added 'ubuntu' to '$GROUP_NAME'."
else
    echo "User 'ubuntu' does not exist; skipping."
fi

# Check if pam_wheel.so is already configured in /etc/pam.d/su
PAM_FILE="/etc/pam.d/su"
PAM_LINE="auth required pam_wheel.so use_uid group=$GROUP_NAME"
if ! grep -Fx "$PAM_LINE" "$PAM_FILE" > /dev/null; then
    echo "Adding pam_wheel.so configuration to $PAM_FILE..."
    echo "$PAM_LINE" >> "$PAM_FILE"
else
    echo "pam_wheel.so configuration already present in $PAM_FILE."
fi

# Verify the configuration
echo "Verifying PAM configuration for su..."
grep "pam_wheel.so" "$PAM_FILE"

echo "Remediation complete: Access to su command is restricted to the '$GROUP_NAME' group (with 'ssm-user' and 'ubuntu' added)."