#!/usr/bin/env python3
import subprocess
from pathlib import Path
import sys

AUDIT_RULE_FILE = Path("/etc/audit/rules.d/50-identity.rules")
RULES = [
    "-w /etc/group -p wa -k identity",
    "-w /etc/passwd -p wa -k identity",
    "-w /etc/gshadow -p wa -k identity",
    "-w /etc/shadow -p wa -k identity",
    "-w /etc/security/opasswd -p wa -k identity",
    "-w /etc/nsswitch.conf -p wa -k identity",
    "-w /etc/pam.conf -p wa -k identity",
    "-w /etc/pam.d -p wa -k identity"
]

def run_command(cmd, ignore_errors=False):
    """Run a shell command silently, optionally ignoring errors."""
    try:
        subprocess.run(cmd, shell=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        if not ignore_errors:
            raise
        return False

def write_rules():
    try:
        # Ensure parent directory exists
        AUDIT_RULE_FILE.parent.mkdir(parents=True, exist_ok=True)

        # Write rules uniquely (avoid duplicates)
        existing_rules = []
        if AUDIT_RULE_FILE.exists():
            with AUDIT_RULE_FILE.open("r") as f:
                existing_rules = [line.strip() for line in f if line.strip()]

        combined = sorted(set(existing_rules + RULES))

        with AUDIT_RULE_FILE.open("w") as f:
            f.write("\n".join(combined) + "\n")

        print(f"✅ Audit rules for identity files written to {AUDIT_RULE_FILE}")
        return True
    except Exception as e:
        print(f"⚠️ Failed to write rules: {e}")
        return False

def load_rules():
    if not run_command("augenrules --load", ignore_errors=True):
        print("⚠️ Could not fully load audit rules via augenrules. Reboot may be required.")

def check_reboot_required():
    try:
        result = subprocess.run("auditctl -s", shell=True, capture_output=True, text=True)
        if "enabled" in result.stdout and "2" in result.stdout:
            print("⚠️ Reboot may be required to fully load rules")
    except Exception:
        pass  # Ignore if auditctl fails

def main():
    success = True

    if not write_rules():
        success = False

    load_rules()
    check_reboot_required()

    if success:
        print("✅ CIS 6.2.3.8 remediation applied successfully (reboot may be required)")
    else:
        print("⚠️ CIS 6.2.3.8 remediation applied with warnings")
    sys.exit(0)

if __name__ == "__main__":
    main()
