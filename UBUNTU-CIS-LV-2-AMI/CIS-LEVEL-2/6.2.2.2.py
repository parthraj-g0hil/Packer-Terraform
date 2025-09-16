#!/usr/bin/env python3
import sys
import os

CONF_FILE = "/etc/audit/auditd.conf"
PARAM = "max_log_file_action"
VALUE = "keep_logs"

def apply_fix():
    if not os.path.exists(CONF_FILE):
        print(f"❌ CIS 6.2.2.2 remediation failed: {CONF_FILE} not found")
        sys.exit(1)

    try:
        updated = False
        lines = []

        with open(CONF_FILE, "r") as f:
            for line in f:
                if line.strip().startswith(PARAM):
                    lines.append(f"{PARAM} = {VALUE}\n")
                    updated = True
                else:
                    lines.append(line)

        if not updated:
            # If parameter not found, append it
            lines.append(f"\n{PARAM} = {VALUE}\n")

        with open(CONF_FILE, "w") as f:
            f.writelines(lines)

        print(f"✅ CIS 6.2.2.2 remediation done: {PARAM} set to {VALUE} (skip auditd restart for Packer)")

    except Exception as e:
        print(f"❌ CIS 6.2.2.2 remediation failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    apply_fix()
