#!/bin/bash
set -euo pipefail

echo "========================================"
echo "Vulnerability: 4.4.1.1 Ensure iptables packages are installed"
echo "========================================"

# Step 1: Update package index
echo "[*] Updating apt package index..."
#apt-get update -y

# Step 2: Install iptables and iptables-persistent
echo "[*] Installing iptables and iptables-persistent..."
DEBIAN_FRONTEND=noninteractive apt-get install -y iptables iptables-persistent

# Step 3: Verify installation
echo "[*] Verifying iptables installation..."
if command -v iptables >/dev/null 2>&1 && command -v ip6tables >/dev/null 2>&1; then
  echo "[OK] iptables installed successfully."
else
  echo "[ERROR] iptables not found after installation." >&2
  exit 1
fi

if dpkg -l | grep -q iptables-persistent; then
  echo "[OK] iptables-persistent installed successfully."
else
  echo "[ERROR] iptables-persistent not found after installation." >&2
  exit 1
fi

echo "========================================"
echo "CIS-compliant iptables installation completed."
echo "========================================"
