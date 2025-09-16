#!/usr/bin/env python3
import sys
from pathlib import Path
import re
import subprocess

AUDIT_CONF_FILE = "/etc/audit/auditd.conf"
SPACE_LEFT_ACTION = "email"
ADMIN_SPACE_LEFT_ACTION = "single"

def set_auditd_param(param, value):
    """Set or append a parameter in auditd.conf"""
    if not Path(AUDIT_CONF_FILE).exists():
        print(f"⚠️ {AUDIT_CONF_FILE} does not exist, skipping {param}")
        return False

    updated = False
    lines = []

    with open(AUDIT_CONF_FILE, "r") as f:
        for line in f:
            if re.match(rf"^\s*{param}\s*=", line):
                lines.append(f"{param} = {value}\n")
                updated = True
            else:
                lines.append(line)

    if not updated:
        lines.append(f"{param} = {value}\n")

    try:
        with open(AUDIT_CONF_FILE, "w") as f:
            f.writelines(lines)
        return True
    except Exception as e:
        print(f"⚠️ Failed to write {AUDIT_CONF_FILE}: {e}")
        return False

def restart_auditd():
    """Restart auditd, ignore failures during Packer builds"""
    try:
        subprocess.run(["systemctl", "restart", "auditd"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        print("⚠️ Could not restart auditd, changes may require a reboot to apply")
        return False

def main():
    success = True

    if not set_auditd_param("space_left_action", SPACE_LEFT_ACTION):
        success = False
    if not set_auditd_param("admin_space_left_action", ADMIN_SPACE_LEFT_ACTION):
        success = False
    if not restart_auditd():
        success = False

    if success:
        print("✅ CIS 6.2.2.4 remediation applied successfully (reboot may be required)")
    else:
        print("⚠️ CIS 6.2.2.4 remediation applied with warnings (auditd may need restart)")
    sys.exit(0)

if __name__ == "__main__":
    main()
