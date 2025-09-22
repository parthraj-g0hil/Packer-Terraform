#!/bin/bash

# Script to remediate CIS 2.3.2.2: Ensure systemd-timesyncd is enabled and running
# Addresses issue where systemd-timesyncd is inactive on server startup
# Assumes Debian/Ubuntu-based system (uses apt-get); modify for other distros if needed

set -e  # Exit on any error

# Update package list
#apt-get update -y

# Install systemd-timesyncd if not already installed
if ! dpkg -l | grep -q '^ii\s*systemd-timesyncd'; then
    echo "Installing systemd-timesyncd..."
    apt-get install -y systemd-timesyncd
fi

# Remove conflicting time sync services like chrony to prevent conflicts
if dpkg -l | grep -q '^ii\s*chrony'; then
    echo "Removing conflicting chrony service..."
    apt-get remove -y --purge chrony
fi

# Configure timesyncd.conf with AWS-recommended NTP servers
echo "Configuring /etc/systemd/timesyncd.conf with AWS NTP servers..."
cat << EOF > /etc/systemd/timesyncd.conf
[Time]
NTP=169.254.169.123
FallbackNTP=0.amazon.pool.ntp.org 1.amazon.pool.ntp.org 2.amazon.pool.ntp.org 3.amazon.pool.ntp.org
EOF

# Unmask the systemd-timesyncd service
echo "Unmasking systemd-timesyncd.service..."
systemctl unmask systemd-timesyncd.service

# Reload systemd daemon to apply changes
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Enable and start systemd-timesyncd (enable ensures it starts on boot)
echo "Enabling and starting systemd-timesyncd.service..."
systemctl enable --now systemd-timesyncd.service

# Verify the service is active and running
echo "Checking systemd-timesyncd status..."
systemctl status systemd-timesyncd.service --no-pager

echo "Remediation complete: systemd-timesyncd is configured, enabled, and running."