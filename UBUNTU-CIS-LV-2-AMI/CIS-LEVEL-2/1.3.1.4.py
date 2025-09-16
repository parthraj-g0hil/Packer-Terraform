#!/usr/bin/env python3
import subprocess
import sys
import os

def run_cmd(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)

def main():
    # Ensure AppArmor tools exist
    if not os.path.exists("/usr/sbin/aa-enforce"):
        print("❌ CIS 1.3.1.4 remediation failed: aa-enforce not found (is apparmor-utils installed?)")
        sys.exit(1)

    # Apply enforce mode to all profiles
    result = run_cmd(["aa-enforce", "/etc/apparmor.d/*"])
    if result.returncode != 0:
        print("❌ CIS 1.3.1.4 remediation failed")
        sys.exit(1)

    print("✅ CIS 1.3.1.4 remediation successful: All AppArmor profiles set to enforce mode")

if __name__ == "__main__":
    main()
