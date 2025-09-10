#!/bin/bash
set -euo pipefail

PWQUALITY_DIR="/etc/security/pwquality.conf.d"
PWQUALITY_FILE="${PWQUALITY_DIR}/50-pwmaxsequence.conf"
MAXSEQUENCE_VALUE="3"

# Ensure directory exists
sudo mkdir -p "$PWQUALITY_DIR"

# Apply maxsequence setting silently
echo "maxsequence = $MAXSEQUENCE_VALUE" | sudo tee "$PWQUALITY_FILE" > /dev/null

# Optional: verify silently (no output to shell)
grep -qi "maxsequence\s*=\s*$MAXSEQUENCE_VALUE" "$PWQUALITY_DIR"/* 2>/dev/null || true
