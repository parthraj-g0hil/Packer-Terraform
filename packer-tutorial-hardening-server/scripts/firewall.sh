#!/bin/bash
set -euo pipefail

echo "🛡️ Automated UFW Firewall Configuration"

# Show currently listening ports and services
echo ""
echo "🔍 Currently open ports and listening services (via netstat):"
sudo netstat -tulpn | grep LISTEN || echo "No active listening ports found."
echo ""

# Check if ufw is installed
if ! command -v ufw &> /dev/null; then
  echo "📦 UFW not found, installing..."
  sudo apt update && sudo apt install -y ufw
fi

# Enable UFW if not already
if sudo ufw status | grep -q inactive; then
  echo "🔐 UFW is inactive, enabling..."
  sudo ufw --force enable
fi

############################################
# Predefined Rules
############################################
# Format: "<action>:<port>:<ip or any>"
# action = allow/deny
# port   = number
# ip     = specific IP or "any"

RULES=(
  "allow:22:any"   # Allow SSH from anywhere
  "allow:80:any"   # Allow HTTP
  "allow:443:any"  # Allow HTTPS
  "deny:21:any"    # Deny FTP
  "allow:8080:any" # Allow 8080 from anywhere
)

############################################
# Apply Rules
############################################
for rule in "${RULES[@]}"; do
  IFS=":" read -r action port ip <<< "$rule"
  
  if [[ "$ip" == "any" ]]; then
    cmd="sudo ufw $action $port/tcp"
  else
    cmd="sudo ufw $action from $ip to any port $port proto tcp"
  fi

  echo "🚀 Applying rule: $cmd"
  $cmd
done

############################################
# Remove Specific Rules (Optional)
############################################
# Example: Delete rules by number (after checking status)
REMOVE_RULES=( )

if [[ ${#REMOVE_RULES[@]} -gt 0 ]]; then
  echo "📋 Current UFW Rules (numbered):"
  sudo ufw status numbered

  for delnum in "${REMOVE_RULES[@]}"; do
    echo "🗑️ Deleting rule #$delnum..."
    yes | sudo ufw delete "$delnum"
  done
fi

############################################
# Final Status
############################################
echo ""
echo "📊 Final UFW Status:"
sudo ufw status verbose
