#!/usr/bin/env python3
import re
from pathlib import Path
import subprocess
import sys

AUDIT_CONF = "/etc/audit/auditd.conf"

# Desired CIS values
DISK_FULL_ACTION = "halt"
DISK_ERROR_ACTION = "halt"

def update_auditd_conf():
    path = Path(AUDIT_CONF)
    if not path.exists():
        print(f"❌ {AUDIT_CONF} not found")
        return False

    try:
        with open(path, "r") as f:
            lines = f.readlines()

        # Remove existing definitions of these parameters
        lines = [re.sub(r"^\s*disk_full_action\s*=.*", "", line) for line in lines]
        lines = [re.sub(r"^\s*disk_error_action\s*=.*", "", line) for line in lines]
        lines = [line for line in lines if line.strip()]

        # Append updated settings
        lines.append(f"disk_full_action = {DISK_FULL_ACTION}\n")
        lines.append(f"disk_error_action = {DISK_ERROR_ACTION}\n")

        with open(path, "w") as f:
            f.writelines(lines)

        print(f"✅ {AUDIT_CONF} updated: disk_full_action={DISK_FULL_ACTION}, disk_error_action={DISK_ERROR_ACTION}")
        return True

    except Exception as e:
        print(f"❌ Failed to update {AUDIT_CONF}: {e}")
        return False

def restart_auditd():
    try:
        subprocess.run(["systemctl", "restart", "auditd"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print("✅ auditd service restarted")
        return True
    except subprocess.CalledProcessError as e:
        print(f"⚠️ Could not restart auditd: {e}")
        return False

def main():
    success = update_auditd_conf()
    if success:
        # Restart auditd to apply changes
        restart_auditd()
        print("✅ CIS 6.2.2.3 remediation applied successfully")
        sys.exit(0)
    else:
        print("❌ CIS 6.2.2.3 remediation failed")
        sys.exit(1)

if __name__ == "__main__":
    main()
