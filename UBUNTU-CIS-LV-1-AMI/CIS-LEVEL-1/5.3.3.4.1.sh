#!/bin/bash
# 5.3.3.4.1 Ensure pam_unix does not include nullok

echo "========================================"
echo "Vulnerability: 5.3.3.4.1 Ensure pam_unix does not include nullok"
echo "========================================"

PAM_FILES=(/etc/pam.d/common-auth /etc/pam.d/common-password /etc/pam.d/common-account /etc/pam.d/common-session)

# Step 1: Check for nullok usage (internal check)
echo "[*] Checking for nullok in PAM configuration..."
nullok_found=false
for file in "${PAM_FILES[@]}"; do
    if [ -f "$file" ] && grep -Pq -- '^\s*([^#\n\r]+\s+)?pam_unix\.so\s+([^#\n\r]+\s+)?nullok\b' "$file"; then
        nullok_found=true
        break
    fi
done

# Step 2: Remediate if needed
if $nullok_found; then
    echo "[*] Removing nullok from PAM configuration files..."
    for file in "${PAM_FILES[@]}"; do
        if [ -f "$file" ]; then
            sudo sed -i 's/\bnullok\b//g' "$file" >/dev/null 2>&1
        fi
    done
else
    echo "✅ nullok not found in PAM files."
fi

# Step 3: Verify internally
nullok_still_present=false
for file in "${PAM_FILES[@]}"; do
    if [ -f "$file" ] && grep -Pq -- '^\s*([^#\n\r]+\s+)?pam_unix\.so\s+([^#\n\r]+\s+)?nullok\b' "$file"; then
        nullok_still_present=true
        break
    fi
done

if $nullok_still_present; then
    echo "❌ nullok is still present. Check manually."
else
    echo "✅ pam_unix nullok removal completed successfully."
fi

echo "========================================"
echo
