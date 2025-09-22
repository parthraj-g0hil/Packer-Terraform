#!/bin/bash

# Script to remediate CIS 6.3.2: Ensure filesystem integrity is regularly checked
# Unmasks and enables dailyaidecheck.timer and dailyaidecheck.service for periodic AIDE checks
# Non-interactive for Packer builds

set -e  # Exit on any error

# Set non-interactive frontend for debconf to prevent prompts
export DEBIAN_FRONTEND=noninteractive

# Check if AIDE is installed (prerequisite from CIS 6.3.1)
if ! dpkg -l | grep -q '^ii\s*aide'; then
    echo "Error: AIDE is not installed. Please remediate CIS 6.3.1 first."
    exit 1
fi

# Unmask dailyaidecheck.timer and dailyaidecheck.service
echo "Unmasking dailyaidecheck.timer and dailyaidecheck.service..."
systemctl unmask dailyaidecheck.timer
systemctl unmask dailyaidecheck.service

# Enable and start dailyaidecheck.timer
echo "Enabling and starting dailyaidecheck.timer..."
systemctl enable --now dailyaidecheck.timer

# Verify the timer and service status
echo "Verifying dailyaidecheck.timer status..."
systemctl status dailyaidecheck.timer --no-pager

echo "Verifying dailyaidecheck.service status..."
systemctl status dailyaidecheck.service --no-pager

echo "Remediation complete: Filesystem integrity checks are scheduled with dailyaidecheck.timer."