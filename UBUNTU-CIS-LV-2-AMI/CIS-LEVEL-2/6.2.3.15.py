#!/usr/bin/env python3
"""
Remediate CIS 6.2.3.15:
Ensure successful and unsuccessful attempts to use the chcon command are collected.
"""

import sys
import os
from pathlib import Path

RULES_FILE = Path("/etc/audit/rules.d/50-perm_chng.rules")
CMD_PATH = "/usr/bin/chcon"

def get_uid_min():
    try:
        with open("/etc/login.defs") as f:
            for line in f:
                if line.strip().startswith("UID_MIN"):
                    return line.split()[1]
    except Exception:
        return None
    return None

def main():
    if os.geteuid() != 0:
        print("Failed: must be run as root")
        sys.exit(1)

    uid_min = get_uid_min()
    if not uid_min:
        print("Failed: UID_MIN not found")
        sys.exit(1)

    rule = f"-a always,exit -F path={CMD_PATH} -F perm=x -F auid>={uid_min} -F auid!=unset -k perm_chng\n"

    try:
        with open(RULES_FILE, "w") as f:
            f.write(rule)
    except Exception as e:
        print(f"Failed: Could not write rules file ({e})")
        sys.exit(1)

    # Skip loading/verification for Packer
    print(f"✅ CIS 6.2.3.15 remediation done (rule written to {RULES_FILE})")

if __name__ == "__main__":
    main()
