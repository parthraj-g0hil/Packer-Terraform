#!/bin/bash
set -euo pipefail

LOGFILE="/root/setup_chrony.log"
exec >"$LOGFILE" 2>&1
echo "⏰ Starting NTP/chrony hardening setup..."

# Install chrony
apt-get update -y
apt-get install -y chrony

# Backup existing config
cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak.$(date +%F-%H%M) || true

# Configure AWS NTP sources (Amazon Time Sync Service works in ap-south-1 and all AWS regions)
cat > /etc/chrony/chrony.conf <<'EOF'
# Chrony configuration for hardened Ubuntu (AWS)
# Use Amazon Time Sync Service (169.254.169.123)
server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4

# Allow local system clock as fallback
local stratum 10

# Record drift
driftfile /var/lib/chrony/chrony.drift

# Log files
logdir /var/log/chrony

# Step the clock if offset > 1 second
makestep 1.0 3

# Enable monitoring
allow 127.0.0.1
allow ::1
EOF

# Restart chrony
systemctl enable --now chrony

# Force sync
chronyc -a makestep || true

echo "✅ Chrony installed, configured, and started."
chronyc tracking || true
chronyc sources -v || true
