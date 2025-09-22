#!/bin/bash

# Script to remediate CIS 4.2.1: Ensure ufw is installed and configured
# Installs ufw, sets secure defaults, and enables it for basic firewall protection

set -e  # Exit on any error

# Update package list
#apt-get update -y

# Install ufw if not already installed
if ! dpkg -l | grep -q '^ii\s*ufw'; then
    echo "Installing Uncomplicated Firewall (ufw)..."
    apt-get install -y ufw
else
    echo "ufw is already installed."
fi

# Reset ufw to default settings to avoid conflicts
echo "Resetting ufw to default settings..."
ufw --force reset

# Set default policies: deny incoming, allow outgoing
echo "Setting default ufw policies: deny incoming, allow outgoing..."
ufw default deny incoming
ufw default allow outgoing

# Allow essential services (e.g., SSH for AWS EC2 access)
echo "Allowing SSH (port 22) for remote access..."
ufw allow 22/tcp

# Enable ufw
echo "Enabling ufw..."
ufw --force enable

# Verify ufw status
echo "Checking ufw status..."
ufw status

echo "Remediation complete: ufw is installed, configured, and enabled."