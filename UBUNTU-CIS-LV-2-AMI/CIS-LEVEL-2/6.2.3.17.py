#!/usr/bin/env python3
import subprocess
from pathlib import Path
import sys
import re
import os

AUDIT_RULE_FILE = Path("/etc/audit/rules.d/50-perm_chng.rules")
AUDIT_KEY = "perm_chng"
TARGET_CMD = "/usr/bin/chacl"

def run_command(cmd, ignore_errors=False):
    try:
        subprocess.run(cmd, shell=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError as e:
        if not ignore_errors:
            raise
        return e.returncode

def ensure_directory():
    dir_path = AUDIT_RULE_FILE.parent
    if not dir_path.exists():
        dir_path.mkdir(parents=True, mode=0o755)

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

def add_audit_rule(uid_min):
    rule = f"-a always,exit -F path={TARGET_CMD} -F perm=x -F auid>={uid_min} -F auid!=unset -k {AUDIT_KEY}"
    ensure_directory()

    # Ensure file exists with correct permissions
    AUDIT_RULE_FILE.touch(mode=0o640, exist_ok=True)
    os.chmod(AUDIT_RULE_FILE, 0o640)

    # Read existing rules and remove duplicates
    try:
        with open(AUDIT_RULE_FILE, "r") as f:
            existing = [line.strip() for line in f.readlines()]
    except Exception:
        existing = []

    if rule not in existing:
        existing.append(rule)

    # Write back sanitized rules (no empty lines, no duplicates)
    with open(AUDIT_RULE_FILE, "w") as f:
        f.writelines(r + "\n" for r in existing)

    print(f"✅ Audit rule added or confirmed in {AUDIT_RULE_FILE}")

def load_audit_rules():
    # Ensure auditd is running
    run_command("systemctl start auditd", ignore_errors=True)

    try:
        run_command("augenrules --load")
        print("✅ Audit rules loaded successfully")
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed to load audit rules: {e}")
        sys.exit(1)

    # Optional: check auditctl status
    result = subprocess.run("auditctl -s", shell=True, capture_output=True, text=True)
    if "enabled" in result.stdout and "2" in result.stdout:
        print("⚠️ Reboot may be required to fully load audit rules")

def main():
    uid_min = get_uid_min()
    if not uid_min:
        print("❌ UID_MIN not found. Cannot apply audit rule.")
        sys.exit(1)

    add_audit_rule(uid_min)
    load_audit_rules()
    print("🎯 CIS 6.2.3.17 remediation completed successfully!")
    sys.exit(0)

if __name__ == "__main__":
    main()
