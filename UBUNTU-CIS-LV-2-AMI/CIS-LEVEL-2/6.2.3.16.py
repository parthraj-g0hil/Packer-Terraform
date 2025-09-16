#!/usr/bin/env python3
import subprocess
from pathlib import Path
import sys
import re

AUDIT_RULE_FILE = Path("/etc/audit/rules.d/50-perm_chng.rules")
SETFACL_PATH = "/usr/bin/setfacl"

def run_command(cmd, ignore_errors=False):
    """Run a shell command silently, optionally ignoring errors."""
    try:
        subprocess.run(cmd, shell=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        if not ignore_errors:
            raise
        return False

def get_uid_min():
    try:
        with open("/etc/login.defs") as f:
            for line in f:
                match = re.match(r"^\s*UID_MIN\s+(\d+)", line)
                if match:
                    return match.group(1)
    except Exception:
        pass
    return None

def rule_exists(rule):
    if AUDIT_RULE_FILE.exists():
        with AUDIT_RULE_FILE.open("r") as f:
            return any(line.strip() == rule.strip() for line in f)
    return False

def write_rule(rule):
    AUDIT_RULE_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not rule_exists(rule):
        with AUDIT_RULE_FILE.open("a") as f:
            f.write(rule + "\n")
        print(f"✅ Audit rule added to {AUDIT_RULE_FILE} for setfacl")
    else:
        print(f"ℹ️ Audit rule already exists in {AUDIT_RULE_FILE}")

def load_audit_rules():
    if not run_command("augenrules --load", ignore_errors=True):
        print("⚠️ Could not fully load audit rules via augenrules. Reboot may be required.")

def check_reboot_required():
    try:
        result = subprocess.run("auditctl -s", shell=True, capture_output=True, text=True)
        if "enabled" in result.stdout and "2" in result.stdout:
            print("⚠️ Reboot may be required to fully load rules")
    except Exception:
        pass

def main():
    uid_min = get_uid_min()
    if not uid_min:
        print("❌ ERROR: UID_MIN variable is unset.")
        sys.exit(1)

    rule = f"-a always,exit -F path={SETFACL_PATH} -F perm=x -F auid>={uid_min} -F auid!=unset -k perm_chng"

    write_rule(rule)
    load_audit_rules()
    check_reboot_required()
    print("✅ CIS 6.2.3.16 remediation applied successfully")
    sys.exit(0)

if __name__ == "__main__":
    main()
