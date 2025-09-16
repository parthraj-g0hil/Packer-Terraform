#!/usr/bin/env python3
import subprocess
import sys
import re

GRUB_FILE = "/etc/default/grub"
PARAM = "audit_backlog_limit=8192"

def run_cmd(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)

def main():
    try:
        # Read grub config
        with open(GRUB_FILE, "r") as f:
            grub_cfg = f.read()

        # Check if param already exists
        if PARAM in grub_cfg:
            print("✅ CIS 6.2.1.4 remediation already applied: audit_backlog_limit set")
            sys.exit(0)

        # Update GRUB_CMDLINE_LINUX line
        new_cfg = []
        updated = False
        for line in grub_cfg.splitlines():
            if line.startswith("GRUB_CMDLINE_LINUX"):
                # Extract current params
                match = re.match(r'GRUB_CMDLINE_LINUX="(.*)"', line)
                if match:
                    current_params = match.group(1)
                    if PARAM not in current_params:
                        new_line = f'GRUB_CMDLINE_LINUX="{current_params} {PARAM}"'
                        new_cfg.append(new_line)
                        updated = True
                    else:
                        new_cfg.append(line)
                else:
                    # No params yet
                    new_cfg.append(f'GRUB_CMDLINE_LINUX="{PARAM}"')
                    updated = True
            else:
                new_cfg.append(line)

        if updated:
            with open(GRUB_FILE, "w") as f:
                f.write("\n".join(new_cfg) + "\n")

            # Apply grub update
            result = run_cmd(["update-grub"])
            if result.returncode != 0:
                print("❌ CIS 6.2.1.4 remediation failed: could not run update-grub")
                sys.exit(1)

            print("✅ CIS 6.2.1.4 remediation successful: audit_backlog_limit applied (reboot required)")

        else:
            print("✅ CIS 6.2.1.4 remediation already applied: no changes needed")

    except Exception as e:
        print(f"❌ CIS 6.2.1.4 remediation failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
