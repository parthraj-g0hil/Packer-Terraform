#!/usr/bin/env python3
import subprocess
from pathlib import Path
import sys

def run_command(cmd, ignore_errors=True):
    """Run a shell command silently, optionally ignoring errors."""
    try:
        subprocess.run(cmd, shell=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        if not ignore_errors:
            raise

def main():
    AUDIT_RULE_FILE = Path("/etc/audit/rules.d/50-user_emulation.rules")
    rules = [
        "-a always,exit -F arch=b64 -C euid!=uid -F auid!=unset -S execve -k user_emulation",
        "-a always,exit -F arch=b32 -C euid!=uid -F auid!=unset -S execve -k user_emulation"
    ]

    try:
        # Ensure directory exists
        AUDIT_RULE_FILE.parent.mkdir(parents=True, exist_ok=True)

        # Read existing rules to avoid duplicates
        if AUDIT_RULE_FILE.exists():
            with AUDIT_RULE_FILE.open("r") as f:
                existing = [line.strip() for line in f.readlines()]
        else:
            existing = []

        # Append only new rules
        with AUDIT_RULE_FILE.open("a") as f:
            for rule in rules:
                if rule not in existing:
                    f.write(rule + "\n")

        print("✅ Audit rules added for user emulation")

        # Load audit rules (ignore errors for Packer)
        run_command("augenrules --load")
        print("✅ Audit rules loaded (may require reboot to fully apply).")
        sys.exit(0)

    except Exception as e:
        print(f"⚠️ Remediation skipped: {e}")
        sys.exit(0)

if __name__ == "__main__":
    main()
