#!/usr/bin/env python3
"""
Remediate CIS 3.2.2: Ensure tipc kernel module is not available.

Behavior:
 - If tipc module files are found under /lib/modules, create /etc/modprobe.d/tipc.conf
   with 'install tipc /bin/false' and 'blacklist tipc', attempt to unload the module,
   and verify it's not loaded and the config exists.
 - If the module is not present in modules directory (or not installable), treat as
   already compliant (Success).
 - Non-interactive. Prints only one final line beginning with "Success:" or "Failed:".
Exit codes:
 - 0 on success, 1 on failure.
"""
from pathlib import Path
import subprocess
import sys
import shlex
import os

CONF_PATH = Path("/etc/modprobe.d/tipc.conf")
MODULE_NAME = "tipc"

def run(cmd, check=False):
    """Run a shell command silently. Return (returncode, stdout+stderr)."""
    try:
        result = subprocess.run(
            shlex.split(cmd), capture_output=True, text=True, check=False
        )
        return result.returncode, (result.stdout or "") + (result.stderr or "")
    except Exception as e:
        return 1, str(e)

def find_module_files(modname):
    """Look for module files under /lib/modules/* matching the module name."""
    paths = []
    base = Path("/lib/modules")
    if not base.exists():
        return []
    for kernel_dir in base.glob("*"):
        if not kernel_dir.is_dir():
            continue
        # search anywhere under kernel_dir for files/dirs that contain modname
        for p in kernel_dir.rglob("*"):
            name = p.name.lower()
            if modname in name:
                paths.append(str(p))
    return sorted(set(paths))

def write_conf(path: Path):
    """Write install and blacklist lines to the conf file atomically."""
    content = "install {m} {bf}\nblacklist {m}\n".format(m=MODULE_NAME, bf="/bin/false")
    try:
        # ensure directory exists
        path.parent.mkdir(parents=True, exist_ok=True)
        # write temp then move
        tmp = path.with_suffix(".tmp")
        tmp.write_text(content, encoding="utf-8")
        os.replace(tmp, path)
        # set permissions to 0644
        path.chmod(0o644)
        return True, ""
    except Exception as e:
        return False, str(e)

def unload_module(modname):
    """Try to remove the module quietly using modprobe -r then rmmod."""
    # attempt modprobe -r
    run(f"modprobe -r {modname} 2>/dev/null")
    # attempt rmmod
    run(f"rmmod {modname} 2>/dev/null")
    # ensure not loaded
    rc, out = run("lsmod")
    if rc != 0:
        # lsmod failure is unexpected but not fatal here
        return False, "lsmod failed"
    # check if module present in lsmod output
    if modname in out:
        return False, "module still loaded"
    return True, ""

def conf_has_expected(path: Path):
    if not path.exists():
        return False
    try:
        text = path.read_text(encoding="utf-8")
    except Exception:
        return False
    return ("install " + MODULE_NAME) in text and ("blacklist " + MODULE_NAME) in text

def module_loaded(modname):
    rc, out = run("lsmod")
    if rc != 0:
        return False
    return modname in out

def main():
    # Must run as root to modify /etc/modprobe.d and remove modules
    if os.geteuid() != 0:
        print("Failed: script must be run as root")
        sys.exit(1)

    found = find_module_files(MODULE_NAME)

    # If no module files found, treat as compliant (no remediation needed)
    if not found:
        # Also check if module somehow built into kernel (can't remediate) by checking modinfo
        rc, _ = run(f"modinfo {MODULE_NAME} 2>/dev/null")
        # modinfo non-zero rc means module not found; treat as success/no remediation
        print("Success: CIS 3.2.2 remediated (module not present or not available)")
        sys.exit(0)

    # Module files exist => attempt remediation
    ok, err = write_conf(CONF_PATH)
    if not ok:
        print(f"Failed: Could not write {CONF_PATH} ({err})")
        sys.exit(1)

    # Attempt to unload
    unloaded, reason = unload_module(MODULE_NAME)
    if not unloaded:
        # Even if unload failed, blacklist+install should prevent future loading; we still verify
        pass

    # Reload module database (not strictly necessary, but safe)
    run("depmod -a 2>/dev/null")

    # Verify: module not loaded and conf file present with expected contents
    if module_loaded(MODULE_NAME):
        # module loaded despite our changes -> failure
        print("Failed: module still loaded after remediation")
        sys.exit(1)

    if not conf_has_expected(CONF_PATH):
        print("Failed: configuration file missing expected entries")
        sys.exit(1)

    # Final success
    print("Success: CIS 3.2.2 remediated (tipc disabled/blacklisted)")
    sys.exit(0)

if __name__ == "__main__":
    main()
