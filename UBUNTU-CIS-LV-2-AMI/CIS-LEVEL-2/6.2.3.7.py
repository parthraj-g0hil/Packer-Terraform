#!/usr/bin/env python3
import subprocess
from pathlib import Path
import sys
import re
import os

RULES_FILE = Path("/etc/audit/rules.d/50-access.rules")
AUDIT_KEY = "access"

def run_command(cmd, ignore_errors=False):
    try:
        subprocess.run(cmd, shell=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError as e:
        if not ignore_errors:
            raise
        return e.returncode

def ensure_directory():
    if not RULES_FILE.parent.exists():
        RULES_FILE.parent.mkdir(parents=True, mode=0o755)

def get_uid_min():
    try:
        with open("/etc/login.defs") as f:
            for line in f:
                match = re.match(r"^\s*UID_MIN\s+(\d+)", line)
                if match:
                    return match.group(1)
    except Exception as e:
        print(f"❌ Failed to read UID_MIN: {e}")
    return None

def build_rules(uid_min):
    rules = [
        f"-a always,exit -F arch=b64 -S creat,open,openat,truncate,ftruncate -F exit=-EACCES -F auid>={uid_min} -F auid!=unset -k {AUDIT_KEY}",
        f"-a always,exit -F arch=b64 -S creat,open,openat,truncate,ftruncate -F exit=-EPERM  -F auid>={uid_min} -F auid!=unset -k {AUDIT_KEY}",
        f"-a always,exit -F arch=b32 -S creat,open,openat,truncate,ftruncate -F exit=-EACCES -F auid>={uid_min} -F auid!=unset -k {AUDIT_KEY}",
        f"-a always,exit -F arch=b32 -S creat,open,openat,truncate,ftruncate -F exit=-EPERM  -F auid>={uid_min} -F auid!=unset -k {AUDIT_KEY}",
    ]
    return rules

def write_rules(rules):
    ensure_directory()
    RULES_FILE.touch(mode=0o640, exist_ok=True)
    os.chmod(RULES_FILE, 0o640)

    # Read existing rules and remove duplicates
    try:
        with open(RULES_FILE, "r") as f:
            existing = set(line.strip() for line in f if line.strip())
    except Exception:
        existing = set()

    new_rules = [r for r in rules if r not in existing]

    if new_rules:
        with open(RULES_FILE, "a") as f:
            f.writelines(r + "\n" for r in new_rules)
        print(f"✅ Audit rules written to {RULES_FILE}")
    else:
        print(f"ℹ️ All rules already exist in {RULES_FILE}")

def load_audit_rules():
    # Ensure auditd is running
    run_command("systemctl start auditd", ignore_errors=True)

    try:
        run_command("augenrules --load")
        result = subprocess.run(f"auditctl -l | grep {AUDIT_KEY}", shell=True, capture_output=True, text=True)
        if AUDIT_KEY in result.stdout:
            print(f"✅ CIS 6.2.3.7 remediation applied successfully")
        else:
            print(f"❌ Failed: Rules not applied")
            sys.exit(1)
    except Exception as e:
        print(f"❌ Failed to load audit rules: {e}")
        sys.exit(1)

def main():
    uid_min = get_uid_min()
    if not uid_min:
        print("❌ UID_MIN not found. Cannot apply audit rules.")
        sys.exit(1)

    rules = build_rules(uid_min)
    write_rules(rules)
    load_audit_rules()

    # Optional: Check if reboot may be required
    try:
        result = subprocess.run("auditctl -s", shell=True, capture_output=True, text=True)
        if "enabled" in result.stdout and "2" in result.stdout:
            print("⚠️ Reboot may be required to fully load audit rules")
    except Exception:
        pass

    sys.exit(0)

if __name__ == "__main__":
    main()
