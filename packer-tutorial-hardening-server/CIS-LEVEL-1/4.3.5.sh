#!/usr/bin/env bash
set -euo pipefail

# CIS 4.3.5 - Ensure nftables base chains exist
# This script will:
# 1. Create the nftables "inet filter" table if missing
# 2. Create input, forward, and output base chains with priority 0
# 3. Add minimal rules to allow SSH and loopback
# 4. Save and enable nftables service

echo "[INFO] Configuring nftables base chains..."

# Ensure nftables is installed
if ! command -v nft >/dev/null 2>&1; then
  echo "[INFO] Installing nftables..."
  apt-get update -y
  apt-get install -y nftables
fi

# Flush any existing rules (safe in Packer AMI build context)
nft flush ruleset || true

# Create config file
cat <<'EOF' >/etc/nftables.conf
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        # Allow loopback
        iif "lo" accept
        ip saddr 127.0.0.0/8 counter drop
        ip6 saddr ::1 counter drop
        # Allow established/related traffic
        ct state established,related accept
        # Allow SSH
        tcp dport 22 accept
    }

    chain forward {
        type filter hook forward priority 0; policy drop;
    }

    chain output {
        type filter hook output priority 0; policy accept;
    }
}
EOF

# Apply rules
nft -f /etc/nftables.conf

# Enable nftables service
systemctl enable nftables
systemctl restart nftables

# Verify
echo "[INFO] nftables chains configured:"
nft list chains
