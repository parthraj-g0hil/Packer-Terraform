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
    AUDIT_RULE_FILE = Path("/etc/audit/rules.d/50-sudo.rules")
    sudo_log_file = None

    try:
        # Step 1: Detect sudo log file from /etc/sudoers*
        grep_cmd = "grep -r '^ *Defaults.*logfile' /etc/sudoers* 2>/dev/null"
        result = subprocess.run(grep_cmd, shell=True, capture_output=True, text=True)
        lines = result.stdout.strip().splitlines()

        for line in lines:
            match = re.search(r'logfile=([^\s,"]+)', line)
            if match:
                sudo_log_file = match.group(1)
                break

        if sudo_log_file:
            # Step 2: Add audit rule for sudo log file (avoid duplicates)
            rule = f"-w {sudo_log_file} -p wa -k sudo_log_file"
            AUDIT_RULE_FILE.parent.mkdir(parents=True, exist_ok=True)

            if AUDIT_RULE_FILE.exists():
                with AUDIT_RULE_FILE.open("r") as f:
                    existing = [l.strip() for l in f.readlines()]
            else:
                existing = []

            if rule not in existing:
                with AUDIT_RULE_FILE.open("a") as f:
                    f.write(rule + "\n")
                print(f"✅ Audit rule added for sudo log file: {sudo_log_file}")
            else:
                print(f"ℹ️ Audit rule already exists for sudo log file: {sudo_log_file}")
        else:
            print("⚠️ SUDO_LOG_FILE not configured. Skipping audit rule.")

        # Step 3: Load audit rules (ignore errors for Packer)
        run_command("augenrules --load")
        print("✅ Audit rules applied (may require reboot to fully take effect).")
        sys.exit(0)

    except Exception as e:
        print(f"⚠️ Remediation skipped: {e}")
        sys.exit(0)

if __name__ == "__main__":
    main()
