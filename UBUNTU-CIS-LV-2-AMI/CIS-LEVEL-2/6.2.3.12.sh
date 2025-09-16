#!/bin/bash
set -euo pipefail

echo "========================================"
echo "🔍 6.2.3.13 Ensure file deletion events are audited"
echo "========================================"

AUDIT_RULE_FILE="/etc/audit/rules.d/50-delete.rules"
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs || echo "")

if [[ -z "$UID_MIN" ]]; then
    echo "❌ ERROR: Could not determine UID_MIN"
    exit 1
fi

# Step 1: Write rules
cat > "${AUDIT_RULE_FILE}" << EOF
# Audit file deletion events
-a always,exit -F arch=b64 -S rename,unlink,unlinkat,renameat -F auid>=${UID_MIN} -F auid!=unset -k delete
-a always,exit -F arch=b32 -S rename,unlink,unlinkat,renameat -F auid>=${UID_MIN} -F auid!=unset -k delete
EOF

echo "✅ Rules written to ${AUDIT_RULE_FILE}"

# Step 2: Load rules
if command -v augenrules >/dev/null 2>&1; then
    augenrules --load
    echo "✅ Audit rules reloaded with augenrules"
elif command -v auditctl >/dev/null 2>&1; then
    auditctl -R "${AUDIT_RULE_FILE}" || true
    echo "⚠️  Rules loaded via auditctl (may require reboot)"
fi

# Step 3: Check if reboot is required
if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
    echo "⚠️  Reboot required to fully load audit rules"
fi

echo "🎉 Remediation for 6.2.3.13 completed"
