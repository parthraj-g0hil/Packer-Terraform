#!/usr/bin/env python3
import subprocess
from pathlib import Path
import sys

def run_command(cmd):
    """Run a shell command silently and ignore errors if specified."""
    try:
        subprocess.run(cmd, shell=True, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        pass  # Ignore errors for commands like rmmod if module not loaded

def main():
    MODULE = "udf"
    CONF_FILE = Path(f"/etc/modprobe.d/{MODULE}.conf")

    try:
        # Check if module is loaded
        lsmod_output = subprocess.run(f"lsmod | grep -q '^{MODULE}'", shell=True)
        if lsmod_output.returncode == 0:
            # Unload module if loaded
            run_command(f"modprobe -r {MODULE}")
            run_command(f"rmmod {MODULE}")
        
        # Write blacklist and disable config
        CONF_FILE.write_text(f"""# Disable {MODULE} filesystem kernel module (CIS 1.1.1.8)
install {MODULE} /bin/false
blacklist {MODULE}
""")

        # Verify config
        with CONF_FILE.open() as f:
            content = f.read()
            if f"install {MODULE}" not in content or f"blacklist {MODULE}" not in content:
                raise RuntimeError("Configuration verification failed.")

        print(f"✅ Remediation complete. {MODULE} module is now disabled.")
        sys.exit(0)

    except Exception as e:
        print(f"❌ Remediation failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
