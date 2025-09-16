#!/usr/bin/env python3
import subprocess
import re
import sys

RULES_FILE = "/etc/audit/rules.d/50-mounts.rules"

def run_cmd(cmd):
    result = subprocess.run(cmd, shell=True, text=True, capture_output=True)
    if result.returncode != 0:
        return None, result.stderr.strip()
    return result.stdout.strip(), None

def get_uid_min():
    try:
        with open("/etc/login.defs", "r") as f:
            for line in f:
                match = re.match(r"^\s*UID_MIN\s+(\d+)", line)
                if match:
                    return match.group(1)
    except Exception:
        return None
    return None

def write_rules(uid_min):
    rules = f"""-a always,exit -F arch=b32 -S mount -F auid>={uid_min} -F auid!=unset -k mounts
-a always,exit -F arch=b64 -S mount -F auid>={uid_min} -F auid!=unset -k mounts
"""
    try:
        with open(RULES_FILE, "w") as f:
            f.write(rules)
        print(f"[OK] Audit rules written to {RULES_FILE}")
    except Exception as e:
        print(f"[ERROR] Failed to write rules: {e}")
        sys.exit(1)

def load_rules():
    out, err = run_cmd("augenrules --load")
    if err:
        print(f"[ERROR] Command failed: augenrules --load\n{err}")
    else:
        print("[OK] Audit rules loaded")

def check_reboot_required():
    out, err = run_cmd("auditctl -s | grep enabled")
    if out and "2" in out:
        print("[INFO] Reboot required to fully apply audit rules")
    else:
        print("[OK] Audit rules applied without reboot")

def main():
    uid_min = get_uid_min()
    if not uid_min:
        print("[ERROR] UID_MIN not found in /etc/login.defs")
        sys.exit(1)

    write_rules(uid_min)
    load_rules()
    check_reboot_required()

if __name__ == "__main__":
    main()
