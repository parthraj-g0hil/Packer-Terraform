#!/bin/bash
# 3.3.9 Ensure suspicious packets are logged (persistent + runtime)

set -euo pipefail

SYSCTL_FILE="/etc/sysctl.d/99-netipv4_logmartians.conf"

echo "🔍 Applying CIS 3.3.9 fix: Ensure suspicious packets are logged"

# Step 1: Persist settings (overwrite any previous file for consistency)
cat <<EOF > "$SYSCTL_FILE"
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
EOF

# Step 2: Apply to running system (all + default)
sysctl -w net.ipv4.conf.all.log_martians=1 >/dev/null
sysctl -w net.ipv4.conf.default.log_martians=1 >/dev/null

# Step 3: Apply to all current interfaces
for iface in $(ls /proc/sys/net/ipv4/conf/); do
    sysctl -w net.ipv4.conf."$iface".log_martians=1 >/dev/null || true
done

# Step 4: Flush routing cache
sysctl -w net.ipv4.route.flush=1 >/dev/null

# Step 5: Verify
echo "✅ Current values:"
sysctl net.ipv4.conf.all.log_martians
sysctl net.ipv4.conf.default.log_martians
