#!/usr/bin/env python3
import sys
import os
import re

RULES_FILE = "/etc/audit/rules.d/50-perm_mod.rules"

AUDIT_RULES = """-a always,exit -F arch=b64 -S chmod,fchmod,fchmodat -F auid>={uid_min} -F auid!=unset -F key=perm_mod
-a always,exit -F arch=b64 -S chown,fchown,lchown,fchownat -F auid>={uid_min} -F auid!=unset -F key=perm_mod
-a always,exit -F arch=b32 -S chmod,fchmod,fchmodat -F auid>={uid_min} -F auid!=unset -F key=perm_mod
-a always,exit -F arch=b32 -S lchown,fchown,chown,fchownat -F auid>={uid_min} -F auid!=unset -F key=perm_mod
-a always,exit -F arch=b64 -S setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>={uid_min} -F auid!=unset -F key=perm_mod
-a always,exit -F arch=b32 -S setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>={uid_min} -F auid!=unset -F key=perm_mod
"""

def get_uid_min():
    try:
        with open("/etc/login.defs", "r") as f:
            for line in f:
                if line.strip().startswith("UID_MIN"):
                    return int(re.findall(r"\d+", line)[0])
    except Exception as e:
        print(f"[ERROR] Unable to get UID_MIN: {e}")
        sys.exit(1)
    print("[ERROR] UID_MIN not found in /etc/login.defs")
    sys.exit(1)

def write_audit_rules(uid_min):
    try:
        rules = AUDIT_RULES.format(uid_min=uid_min).strip() + "\n"
        os.makedirs(os.path.dirname(RULES_FILE), exist_ok=True)

        if os.path.exists(RULES_FILE):
            with open(RULES_FILE, "r") as f:
                existing = f.read()
        else:
            existing = ""

        new_content = existing.strip().splitlines() + rules.strip().splitlines()
        deduped = sorted(set([line.strip() for line in new_content if line.strip()]))

        with open(RULES_FILE, "w") as f:
            f.write("\n".join(deduped) + "\n")

        print(f"[OK] Audit rules written to {RULES_FILE}")
    except Exception as e:
        print(f"[ERROR] Failed to write audit rules: {e}")
        sys.exit(1)

def main():
    uid_min = get_uid_min()
    write_audit_rules(uid_min)
    # Skip loading audit rules for Packer
    print(f"[INFO] CIS 6.2.3.x remediation done (rules written, skipping augenrules load)")

if __name__ == "__main__":
    main()
