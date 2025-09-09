#!/bin/bash
# 7.1.12 Ensure no files or directories without an owner and a group exist

echo "========================================"
echo "Vulnerability: 7.1.12 Ensure no files or directories without an owner and a group exist"
echo "========================================"

# Step 1: Check for files/directories without owner or group
echo "[*] Checking for files or directories without an owner or group..."
ORPHAN_FILES=$(sudo find / -xdev \( -nouser -o -nogroup \) -print)

if [ -z "$ORPHAN_FILES" ]; then
    echo "[*] No orphaned files or directories found."
else
    echo "[!] Orphaned files/directories detected:"
    echo "$ORPHAN_FILES"

    # Step 2: Remediate - assign root:root to orphaned files
    echo "[*] Remediating orphaned files/directories..."
    echo "$ORPHAN_FILES" | while read -r file; do
        sudo chown root:root "$file"
    done
fi

# Step 3: Verify again
echo "[*] Verifying no files/directories without owner or group exist..."
sudo find / -xdev \( -nouser -o -nogroup \) -print || echo "[*] Verification complete. No orphaned files remain."

echo "========================================"
echo "Orphaned file remediation completed."
echo
