#!/bin/bash
# 3.3.9 Ensure suspicious packets are logged (silent, Packer-friendly)

SYSCTL_FILE="/etc/sysctl.d/60-netipv4_sysctl.conf"

# Step 1: Persist settings (overwrite any previous file)
sudo tee "$SYSCTL_FILE" > /dev/null <<EOF
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
EOF

# Step 2: Apply immediately
sudo sysctl -w net.ipv4.conf.all.log_martians=1 >/dev/null 2>&1
sudo sysctl -w net.ipv4.conf.default.log_martians=1 >/dev/null 2>&1
sudo sysctl -w net.ipv4.route.flush=1 >/dev/null 2>&1
