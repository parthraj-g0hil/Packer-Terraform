#!/bin/bash
set -euo pipefail

echo "========================================"
echo "CIS UFW Firewall Setup: Default Deny + Open Ports"
echo "========================================"

# Step 1: Ensure UFW is installed
if ! command -v ufw >/dev/null 2>&1; then
  echo "[*] Installing ufw..."
  apt-get update -qq
  apt-get install -y ufw >/dev/null 2>&1
fi

# Step 2: Reset UFW
echo "[*] Resetting UFW..."
ufw --force reset >/dev/null 2>&1

# Step 3: Set default deny policies
echo "[*] Setting default deny policies..."
ufw default deny incoming >/dev/null 2>&1
ufw default deny outgoing >/dev/null 2>&1
ufw default deny routed >/dev/null 2>&1

# Step 4: Allow SSH
echo "[*] Allowing SSH (22/tcp)..."
ufw allow in 22/tcp >/dev/null 2>&1
ufw allow out 22/tcp >/dev/null 2>&1

# Step 5: Detect other open ports and deny them
echo "[*] Detecting open listening ports..."
open_ports=$(ss -tuln | awk 'NR>1 {print $5}' | awk -F: '{print $NF}' | sort -u | grep -E '^[0-9]+$' || true)
for port in $open_ports; do
    if [[ "$port" -ne 22 ]]; then
        echo "[*] Denying port $port..."
        ufw deny in "$port" comment "Deny inbound port $port" >/dev/null 2>&1
    fi
done

# Step 6: Enable logging
echo "[*] Enabling UFW logging..."
ufw logging on >/dev/null 2>&1

# Step 7: Enable UFW (force)
echo "[*] Enabling UFW..."
ufw --force enable >/dev/null 2>&1

# Step 8: Reload and verify
echo "[*] Reloading UFW..."
ufw reload >/dev/null 2>&1

echo "[*] Final UFW status:"
ufw status verbose

echo "========================================"
echo "CIS-compliant UFW firewall rules applied (only SSH open)."
echo "========================================"
