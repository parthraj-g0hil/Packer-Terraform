#!/usr/bin/env python3
import subprocess
from pathlib import Path
import sys
import re
import os

AUDIT_RULE_FILE = Path("/etc/audit/rules.d/50-kernel_modules.rules")

def run_command(cmd, ignore_errors=True):
    """Run a shell command silently, optionally ignoring errors."""
    try:
        subprocess.run(cmd, shell=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        if not ignore_errors:
            raise

def get_uid_min():
    try:
        with open("/etc/login.defs") as f:
            for line in f:
                match = re.match(r"^\s*UID_MIN\s+(\d+)", line)
                if match:
                    return match.group(1)
    except Exception:
        return None
    return None

def main():
    try:
        uid_min = get_uid_min()
        if not uid_min:
            print("⚠️ UID_MIN not found. Using default 1000.")
            uid_min = "1000"

        # Ensure directory exists
        os.makedirs(AUDIT_RULE_FILE.parent, exist_ok=True)

        # Prepare audit rules
        rules = [
            f"-a always,exit -F arch=b64 -S init_module,finit_module,delete_module,create_module,query_module -F auid>={uid_min} -F auid!=unset -k kernel_modules\n",
            f"-a always,exit -F path=/usr/bin/kmod -F perm=x -F auid>={uid_min} -F auid!=unset -k kernel_modules\n"
        ]

        # Avoid duplicate entries
        existing = []
        if AUDIT_RULE_FILE.exists():
            with open(AUDIT_RULE_FILE) as f:
                existing = [line.strip() for line in f.readlines()]

        with open(AUDIT_RULE_FILE, "w") as f:
            for rule in rules:
                if rule.strip() not in existing:
                    f.write(rule)

        print("✅ Audit rules added for kernel module loading/unloading")

        # Load rules safely
        run_command("augenrules --load")
        print("✅ Audit rules loaded (errors ignored). Reboot may be required to fully apply rules.")

    except Exception as e:
        print(f"❌ Remediation failed: {e}")

if __name__ == "__main__":
    main()
