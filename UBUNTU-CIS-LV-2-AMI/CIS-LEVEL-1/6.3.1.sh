#!/bin/bash

# Script to remediate CIS 6.3.1: Ensure AIDE is installed and initialized
# Handles non-interactive installation to avoid postfix prompts
# Suppresses output to /dev/null for clean Packer build logs

set -e  # Exit on any error

# Set non-interactive frontend for debconf to prevent prompts
export DEBIAN_FRONTEND=noninteractive

# Preconfigure postfix to avoid interactive dialog (choose 'No configuration')
echo "postfix postfix/main_mailer_type select No configuration" | debconf-set-selections >/dev/null 2>&1

# Update package list
apt-get update -y >/dev/null 2>&1

# Install AIDE and aide-common without triggering interactive prompts
apt-get install -y --no-install-recommends aide aide-common >/dev/null 2>&1

# Create a basic AIDE configuration if not already present
if [ ! -f /etc/aide/aide.conf ]; then
    cat << EOF > /etc/aide/aide.conf
# AIDE configuration for basic filesystem monitoring
@@define DBDIR /var/lib/aide
@@define LOGDIR /var/log/aide
database=file:@@{DBDIR}/aide.db
database_out=file:@@{DBDIR}/aide.db.new
gzip_dbout=yes
verbose=5
report_url=file:@@{LOGDIR}/aide.log
report_url=stdout

# Directories to monitor (basic critical system paths)
/bin    Perm+Inode+Sha512
/boot   Perm+Inode+Sha512
/etc    Perm+Inode+Sha512
/lib    Perm+Inode+Sha512
/sbin   Perm+Inode+Sha512
/usr    Perm+Inode+Sha512
/var    Perm+Inode+Sha512
!/var/log/.*
!/var/run/.*
!/var/lib/aide/.*

# Example rule definitions
Perm = p+u+g+acl+selinux+xattrs
Inode = i+n
Sha512 = sha512
EOF
fi

# Set permissions on AIDE configuration
chmod 644 /etc/aide/aide.conf >/dev/null 2>&1

# Initialize AIDE database
aideinit --force >/dev/null 2>&1

# Move the initialized database to the correct location
mv -f /var/lib/aide/aide.db.new /var/lib/aide/aide.db >/dev/null 2>&1

# Verify AIDE database with explicit config file
aide --config /etc/aide/aide.conf --check >/dev/null 2>&1