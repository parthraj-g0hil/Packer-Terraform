#!/usr/bin/env python3
import subprocess
import sys
import re

GRUB_FILE = "/etc/default/grub"

def remediate_auditd_prestartup():
    try:
        # Read grub config
        with open(GRUB_FILE, "r") as f:
            grub_cfg = f.read()

        # Ensure GRUB_CMDLINE_LINUX line exists
        match = re.search(r'GRUB_CMDLINE_LINUX="([^"]*)"', grub_cfg)
        if not match:
            print("❌ CIS 6.2.1.3 remediation failed: GRUB_CMDLINE_LINUX not found")
            sys.exit(1)

        current_args = match.group(1).strip()
        args = current_args.split()

        # Add audit=1 if missing
        if "audit=1" not in args:
            args.append("audit=1")

        new_args = " ".join(args)
        new_line = f'GRUB_CMDLINE_LINUX="{new_args}"'
        grub_cfg = re.sub(r'GRUB_CMDLINE_LINUX="[^"]*"', new_line, grub_cfg)

        # Write back config
        with open(GRUB_FILE, "w") as f:
            f.write(grub_cfg)

        # Update grub
        subprocess.run(["update-grub"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        print("✅ CIS 6.2.1.3 remediation applied successfully")

    except Exception as e:
        print(f"❌ CIS 6.2.1.3 remediation failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    remediate_auditd_prestartup()
