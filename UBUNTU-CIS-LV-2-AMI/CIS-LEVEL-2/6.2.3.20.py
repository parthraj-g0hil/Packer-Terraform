#!/usr/bin/env python3
import subprocess
import sys
import os

RULES_FILE = "/etc/audit/rules.d/99-finalize.rules"

def run_cmd(cmd):
    result = subprocess.run(cmd, shell=True, text=True, capture_output=True)
    if result.returncode != 0:
        return None, result.stderr.strip()
    return result.stdout.strip(), None

def ensure_immutable_rule():
    try:
        # Ensure directory exists
        os.makedirs(os.path.dirname(RULES_FILE), exist_ok=True)

        # Check if file exists & already has -e 2
        if os.path.exists(RULES_FILE):
            with open(RULES_FILE, "r") as f:
                content = f.read()
                if "-e 2" in content:
                    print(f"[OK] Immutable audit rule already present in {RULES_FILE}")
                    return

        # Append rule
        with open(RULES_FILE, "a") as f:
            f.write("\n-e 2\n")

        print(f"[OK] Immutable audit rule added to {RULES_FILE}")

    except Exception as e:
        print(f"[ERROR] Failed to configure immutable rule: {e}")
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
        print("[INFO] Reboot required to apply immutable audit rules")
    else:
        print("[OK] Audit rules applied (immutable after reboot)")

def main():
    ensure_immutable_rule()
    load_rules()
    check_reboot_required()

if __name__ == "__main__":
    main()
