#!/bin/bash
# 4.3.8 Ensure nftables default deny firewall policy

echo "========================================"
echo "Vulnerability: 4.3.8 Ensure nftables default deny firewall policy"
echo "========================================"

TABLE_NAME="filter"
FAMILY="inet"

# Step 1: Ensure the table exists
if ! sudo nft list tables | grep -qw "$TABLE_NAME"; then
    echo "[*] Creating nftables table $TABLE_NAME..."
    sudo nft add table $FAMILY $TABLE_NAME
fi

# Step 2: Ensure base chains exist
for CHAIN in input forward output; do
    if ! sudo nft list chain $FAMILY $TABLE_NAME $CHAIN >/dev/null 2>&1; then
        echo "[*] Creating base chain $CHAIN..."
        case $CHAIN in
            input) HOOK="input"; PRIORITY=0 ;;
            forward) HOOK="forward"; PRIORITY=0 ;;
            output) HOOK="output"; PRIORITY=0 ;;
        esac
        sudo nft add chain $FAMILY $TABLE_NAME $CHAIN "{ type filter hook $HOOK priority $PRIORITY; policy accept; }"
    fi
done

# Step 3: Add SSH allow rule in input chain (if not already present)
if ! sudo nft list chain $FAMILY $TABLE_NAME input | grep -q "tcp dport 22 accept"; then
    echo "[*] Adding SSH allow rule..."
    sudo nft add rule $FAMILY $TABLE_NAME input tcp dport 22 accept
fi

# Step 4: Set default policy to DROP for all base chains
for CHAIN in input forward output; do
    echo "[*] Setting default policy to DROP for chain $CHAIN..."
    sudo nft "chain $FAMILY $TABLE_NAME $CHAIN { policy drop; }"
done

# Step 5: Verify ruleset
echo "[*] Current nftables ruleset:"
sudo nft list ruleset

echo "========================================"
echo "nftables default deny policy applied successfully."
echo "========================================"
