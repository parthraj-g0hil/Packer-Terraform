#!/usr/bin/env python3
import os
import subprocess
from pathlib import Path
import sys

RULES_FILE = Path("/etc/audit/rules.d/50-system_locale.rules")
AUDIT_KEY = "system-locale"

AUDIT_RULES = [
    "-a always,exit -F arch=b64 -S sethostname,setdomainname -k system-locale\n",
    "-a always,exit -F arch=b32 -S sethostname,setdomainname -k system-locale\n",
    "-w /etc/issue -p wa -k system-locale\n",
    "-w /etc/issue.net -p wa -k system-locale\n",
    "-w /etc/hosts -p wa -k system-locale\n",
    "-w /etc/networks -p wa -k system-locale\n",
    "-w /etc/network/ -p wa -k system-locale\n",
    "-w /etc/netplan/ -p wa -k system-locale\n"
]

def run_command(cmd, ignore_errors=False):
    """Run a shell command silently."""
    try:
        subprocess.run(cmd, shell=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        if not ignore_errors:
            raise

def ensure_directory():
    """Ensure audit rules directory exists."""
    if not RULES_FILE.parent.exists():
        RULES_FILE.parent.mkdir(parents=True, mode=0o755)

def write_rules():
    """Write audit rules idempotently and ensure file permissions."""
    ensure_directory()
    RULES_FILE.touch(mode=0o640, exist_ok=True)
    os.chmod(RULES_FILE, 0o640)

    try:
        with open(RULES_FILE, "r") as f:
            existing = set(line.strip() for line in f if line.strip())
    except Exception:
        existing = set()

    new_lines = [rule for rule in AUDIT_RULES if rule.strip() not in existing]

    if new_lines:
        with open(RULES_FILE, "a") as f:
            f.writelines(new_lines)
        print(f"✅ Audit rules written to {RULES_FILE}")
    else:
        print(f"ℹ️ All audit rules already exist in {RULES_FILE}")

def load_audit_rules():
    """Load audit rules safely."""
    # Start auditd if not running
    run_command("systemctl start auditd", ignore_errors=True)

    try:
        run_command("augenrules --load")
        result = subprocess.run(f"auditctl -l | grep {AUDIT_KEY}", shell=True, capture_output=True, text=True)
        if AUDIT_KEY in result.stdout:
            print(f"✅ CIS 6.2.3.X remediation applied successfully")
        else:
            print(f"❌ Failed: Rules not applied")
            sys.exit(1)
    except Exception as e:
        print(f"❌ Failed to load audit rules: {e}")
        sys.exit(1)

def main():
    write_rules()
    load_audit_rules()

    # Optional: check if reboot may be required
    try:
        result = subprocess.run("auditctl -s", shell=True, capture_output=True, text=True)
        if "enabled" in result.stdout and "2" in result.stdout:
            print("⚠️ Reboot may be required to fully load audit rules")
        else:
            print("✅ Audit rules applied without reboot")
    except Exception:
        pass

if __name__ == "__main__":
    main()
