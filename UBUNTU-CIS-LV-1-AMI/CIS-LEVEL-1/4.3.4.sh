#!/bin/bash
set -euo pipefail

echo "========================================"
echo "Vulnerability: 4.3.4 Ensure a nftables table exists"
echo "========================================"

# Step 1: Ensure nftables is installed
if ! command -v nft >/dev/null 2>&1; then
  echo "[*] Installing nftables..."
  apt-get install -y nftables
fi

# Step 2: Enable nftables service
echo "[*] Enabling and starting nftables..."
systemctl enable nftables
systemctl start nftables

# Step 3: Check if "inet filter" table exists, if not create it
if ! nft list tables | grep -q "table inet filter"; then
  echo "[*] Creating nftables table 'inet filter'..."
  nft create table inet filter
else
  echo "[*] Table 'inet filter' already exists. Skipping creation."
fi

# Step 4: Save configuration to /etc/nftables.conf
echo "[*] Saving nftables configuration..."
nft list ruleset > /etc/nftables.conf

# Step 5: Verify
echo "[*] Verifying nftables table..."
nft list tables

echo "========================================"
echo "CIS-compliant nftables table setup completed."
echo "========================================"
