#!/bin/bash

# Script to remediate CIS 4.2.1, 4.2.3, 4.2.6-7: UFW installation, service enablement, and configuration
# Installs UFW, enables the service, sets secure policies, allows essential ports (including 80/tcp and 443/tcp), denies unnecessary ports, and enables logging
# Non-interactive for Packer builds

set -euo pipefail  # Exit on error, undefined variables, or pipeline failures

# Set non-interactive frontend for debconf to prevent prompts
export DEBIAN_FRONTEND=noninteractive

echo "========================================"
echo "Remediating CIS 4.2.1, 4.2.3, 4.2.6-7: UFW configuration"
echo "========================================"

# Install UFW if not already installed (CIS 4.2.1)
if ! dpkg -l | grep -q '^ii\s*ufw'; then
    echo "[*] Installing Uncomplicated Firewall (ufw)..."
    apt-get update -y
    apt-get install -y --no-install-recommends ufw
else
    echo "[*] ufw is already installed."
fi

# Unmask UFW service (CIS 4.2.3)
echo "[*] Unmasking ufw.service..."
systemctl unmask ufw.service || true

# Reset UFW to default settings to avoid conflicts (CIS 4.2.1)
echo "[*] Resetting ufw to default settings..."
ufw --force reset >/dev/null 2>&1

# Set default policies: deny incoming, deny outgoing, deny routed (CIS 4.2.6)
echo "[*] Setting default UFW policies: deny incoming, deny outgoing, deny routed..."
ufw default deny incoming >/dev/null 2>&1
ufw default deny outgoing >/dev/null 2>&1
ufw default deny routed >/dev/null 2>&1

# Allow essential outbound ports (CIS 4.2.6)
ESSENTIAL_OUT=(
    "22/tcp"   # SSH
    "53/tcp"   # DNS
    "80/tcp"   # HTTP
    "443/tcp"  # HTTPS
    "853/tcp"  # DNS over TLS
)
for port in "${ESSENTIAL_OUT[@]}"; do
    if ! ufw status | grep -qE "^${port}[[:space:]]+ALLOW OUT"; then
        echo "[*] Allowing outbound ${port}..."
        ufw allow out "$port" >/dev/null 2>&1
    fi
done

# Allow essential inbound ports (CIS 4.2.3, 4.2.6)
if ! ufw status | grep -qE "^22/tcp[[:space:]]+ALLOW IN"; then
    echo "[*] Allowing inbound SSH (22/tcp)..."
    ufw allow in 22/tcp comment 'Allow SSH for remote access' >/dev/null 2>&1
fi
if ! ufw status | grep -qE "^80/tcp[[:space:]]+ALLOW IN"; then
    echo "[*] Allowing inbound HTTP (80/tcp)..."
    ufw allow in 80/tcp comment 'Allow HTTP for web access' >/dev/null 2>&1
fi
if ! ufw status | grep -qE "^443/tcp[[:space:]]+ALLOW IN"; then
    echo "[*] Allowing inbound HTTPS (443/tcp)..."
    ufw allow in 443/tcp comment 'Allow HTTPS for secure web access' >/dev/null 2>&1
fi

# Deny unnecessary open ports (CIS 4.2.7)
echo "[*] Checking for unnecessary open ports to deny..."
open_ports=$(ss -tuln | awk 'NR>1 {print $5}' | awk -F: '{print $NF}' | sort -u | grep -E '^[0-9]+$' || true)
for port in $open_ports; do
    case "$port" in
        22|53|80|443|853) continue ;;  # Skip essential ports
    esac
    if ! ufw status | grep -qE "^${port}/tcp[[:space:]]+DENY IN"; then
        echo "[*] Denying inbound ${port}/tcp..."
        ufw deny in "${port}/tcp" >/dev/null 2>&1
    fi
    if ! ufw status | grep -qE "^${port}/udp[[:space:]]+DENY IN"; then
        echo "[*] Denying inbound ${port}/udp..."
        ufw deny in "${port}/udp" >/dev/null 2>&1
    fi
done

# Enable UFW logging (CIS 4.2.7)
if ! ufw status verbose | grep -qw "Logging: on"; then
    echo "[*] Enabling UFW logging..."
    ufw logging on >/dev/null 2>&1
fi

# Enable and start UFW service (CIS 4.2.3)
echo "[*] Enabling and starting ufw.service..."
systemctl --now enable ufw.service >/dev/null 2>&1

# Force enable UFW to apply rules (CIS 4.2.1, 4.2.3)
echo "[*] Enabling UFW..."
ufw --force enable >/dev/null 2>&1

# Reload UFW rules (CIS 4.2.6-7)
echo "[*] Reloading UFW rules..."
ufw reload >/dev/null 2>&1

# Verify UFW status and rules
echo "[*] Verifying UFW service and rules..."
systemctl status ufw.service --no-pager
ufw status verbose

echo "========================================"
echo "Remediation complete: CIS 4.2.1, 4.2.3, 4.2.6-7 applied. UFW is installed, enabled, and configured with HTTP and HTTPS."
echo "========================================"