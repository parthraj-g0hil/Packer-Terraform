#!/bin/bash
# CIS UFW Firewall Setup: Non-destructive, safe for Packer builds
set -euo pipefail

# Step 1: Ensure UFW is installed
if ! command -v ufw >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y ufw >/dev/null 2>&1
fi

# Step 2: Enable UFW if not already
if ufw status | grep -qw inactive; then
    ufw --force enable >/dev/null 2>&1
fi

# Step 3: Ensure default deny policies are set
ufw default deny incoming >/dev/null 2>&1
ufw default deny outgoing >/dev/null 2>&1
ufw default deny routed >/dev/null 2>&1

# Step 4: Ensure essential outbound ports are allowed
ESSENTIAL_OUT=(
  "22/tcp"   # SSH
  "53/tcp"   # DNS
  "53/udp"   # DNS
  "80/tcp"   # HTTP
  "443/tcp"  # HTTPS
  "123/udp"  # NTP
  "853/tcp"  # DNS over TLS
)
for port in "${ESSENTIAL_OUT[@]}"; do
    if ! ufw status | grep -qE "^${port}[[:space:]]+ALLOW OUT"; then
        ufw allow out "$port" >/dev/null 2>&1
    fi
done

# Step 5: Ensure SSH inbound is allowed
if ! ufw status | grep -qE "^22/tcp[[:space:]]+ALLOW IN"; then
    ufw allow in 22/tcp >/dev/null 2>&1
fi

# Step 6: Detect other open listening ports and add deny rules (only if no rule exists)
open_ports=$(ss -tuln | awk 'NR>1 {print $5}' | awk -F: '{print $NF}' | sort -u | grep -E '^[0-9]+$' || true)
for port in $open_ports; do
    # Skip essential ports
    case "$port" in
        22|53|80|443|123|853) continue ;;
    esac

    if ! ufw status | grep -qE "^${port}/tcp[[:space:]]+DENY IN"; then
        ufw deny in "${port}/tcp" >/dev/null 2>&1
    fi
    if ! ufw status | grep -qE "^${port}/udp[[:space:]]+DENY IN"; then
        ufw deny in "${port}/udp" >/dev/null 2>&1
    fi
done

# Step 7: Enable logging if not already
if ! ufw status verbose | grep -qw "Logging: on"; then
    ufw logging on >/dev/null 2>&1
fi

# Step 8: Reload rules silently
ufw reload >/dev/null 2>&1
