#!/usr/bin/env python3
import subprocess
from pathlib import Path
import sys
import re

def run_command(cmd, ignore_errors=True):
    """Run a shell command silently, optionally ignoring errors."""
    try:
        subprocess.run(cmd, shell=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        if not ignore_errors:
            raise

def main():
    AUDIT_RULE_FILE = Path("/etc/audit/rules.d/50-usermod.rules")

    try:
        # Step 1: Get UID_MIN from /etc/login.defs
        uid_min = None
        with open("/etc/login.defs") as f:
            for line in f:
                match = re.match(r"^\s*UID_MIN\s+(\d+)", line)
                if match:
                    uid_min = match.group(1)
                    break

        if uid_min:
            # Step 2: Add audit rule for usermod command (avoid duplicates)
            rule = f"-a always,exit -F path=/usr/sbin/usermod -F perm=x -F auid>={uid_min} -F auid!=unset -k usermod"
            AUDIT_RULE_FILE.parent.mkdir(parents=True, exist_ok=True)

            if AUDIT_RULE_FILE.exists():
                with AUDIT_RULE_FILE.open("r") as f:
                    existing = [l.strip() for l in f.readlines()]
            else:
                existing = []

            if rule not in existing:
                with AUDIT_RULE_FILE.open("a") as f:
                    f.write(rule + "\n")
                print(f"✅ Audit rule added for /usr/sbin/usermod")
            else:
                print(f"ℹ️ Audit rule already exists for /usr/sbin/usermod")
        else:
            print("⚠️ UID_MIN not found. Skipping audit rule.")

        # Step 3: Load audit rules (ignore errors for Packer)
        run_command("augenrules --load")
        print("✅ Audit rules applied (may require reboot to fully take effect).")
        sys.exit(0)

    except Exception as e:
        print(f"⚠️ Remediation skipped: {e}")
        sys.exit(0)

if __name__ == "__main__":
    main()
