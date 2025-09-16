#!/usr/bin/env python3
import subprocess
from pathlib import Path
import sys

def run_command(cmd, ignore_errors=False):
    """Run a shell command silently, optionally ignoring errors."""
    try:
        subprocess.run(cmd, shell=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        if not ignore_errors:
            raise

def main():
    MODULE = "sctp"
    CONF_FILE = Path(f"/etc/modprobe.d/{MODULE}.conf")

    try:
        # Step 1: Write blacklist and disable config
        CONF_FILE.write_text(f"""install {MODULE} /bin/false
blacklist {MODULE}
""")

        # Step 2: Attempt to unload module if loaded
        run_command(f"modprobe -r {MODULE}", ignore_errors=True)
        run_command(f"rmmod {MODULE}", ignore_errors=True)

        # Step 3: Update initramfs
        run_command("update-initramfs -u", ignore_errors=True)

        # Step 4: Verify module cannot be loaded
        result = subprocess.run(f"modprobe {MODULE}", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if result.returncode == 0:
            # Cleanup if module still loaded
            run_command(f"rmmod {MODULE}", ignore_errors=True)
            print(f"❌ {MODULE.upper()} remediation failed (module still loadable)")
            sys.exit(1)
        else:
            print(f"✅ {MODULE.upper()} remediation successful (module blocked)")
            sys.exit(0)

    except Exception as e:
        print(f"❌ Remediation failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
