#!/bin/bash
# 4.3.10 Ensure nftables rules are permanent

echo "========================================"
echo "Vulnerability: 4.3.10 Ensure nftables rules are permanent"
echo "========================================"

NFT_CONF="/etc/nftables.conf"
NFT_RULES="/etc/nftables.rules"

# Step 1: Create nftables.rules if it doesn't exist
if [ ! -f "$NFT_RULES" ]; then
    echo "[*] Creating $NFT_RULES with default base chains and SSH allowed..."
    sudo tee $NFT_RULES > /dev/null <<EOF
#!/usr/sbin/nft -f

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        iif "lo" accept
        ip saddr 127.0.0.0/8 counter drop
        ip6 saddr ::1 counter drop
        ct state established,related accept
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
else
    echo "[*] $NFT_RULES already exists. Skipping creation."
fi

# Step 2: Ensure /etc/nftables.conf includes the rules file
if ! grep -q "^include \"$NFT_RULES\"" "$NFT_CONF"; then
    echo "[*] Adding include line to $NFT_CONF..."
    echo "include \"$NFT_RULES\"" | sudo tee -a "$NFT_CONF" > /dev/null
else
    echo "[*] Include line already present in $NFT_CONF"
fi

# Step 3: Load the ruleset immediately
echo "[*] Loading nftables rules..."
sudo nft -f "$NFT_RULES"

# Step 4: Enable nftables service for persistence
echo "[*] Enabling nftables service..."
sudo systemctl enable nftables
sudo systemctl restart nftables

# Step 5: Verify
echo "[*] Verifying nftables rules..."
sudo nft list ruleset

echo "========================================"
echo "nftables rules are now permanent and applied on boot."
echo "========================================"
