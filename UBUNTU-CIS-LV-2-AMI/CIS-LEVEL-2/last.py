#!/usr/bin/env python3
import subprocess
from pathlib import Path
import sys

SYSCTL_FILE = Path("/etc/sysctl.d/99-netipv4_logmartians.conf")
SERVICE = "systemd-timesyncd"

def run_cmd(cmd, check=True, capture=False):
    """Run shell command silently"""
    try:
        if capture:
            return subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL).strip()
        else:
            subprocess.run(cmd, check=check, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        if check:
            sys.exit(1)
        return None

def apply_log_martians():
    # Persist sysctl config
    SYSCTL_FILE.write_text(
        "net.ipv4.conf.all.log_martians = 1\n"
        "net.ipv4.conf.default.log_martians = 1\n"
    )

    # Runtime apply
    run_cmd(["sysctl", "-w", "net.ipv4.conf.all.log_martians=1"])
    run_cmd(["sysctl", "-w", "net.ipv4.conf.default.log_martians=1"])

    # Apply to all interfaces
    try:
        for iface in Path("/proc/sys/net/ipv4/conf/").iterdir():
            run_cmd(["sysctl", "-w", f"net.ipv4.conf.{iface.name}.log_martians=1"], check=False)
    except FileNotFoundError:
        pass

    # Flush routing cache
    run_cmd(["sysctl", "-w", "net.ipv4.route.flush=1"])

def ensure_timesyncd():
    run_cmd(["systemctl", "enable", f"{SERVICE}.service"], check=False)
    run_cmd(["systemctl", "start", f"{SERVICE}.service"], check=False)

def main():
    apply_log_martians()
    ensure_timesyncd()

    # Minimal final check
    enabled = run_cmd(["systemctl", "is-enabled", f"{SERVICE}.service"], capture=True)
    active = run_cmd(["systemctl", "is-active", f"{SERVICE}.service"], capture=True)
    sync_status = run_cmd(["timedatectl", "show", "-p", "NTPSynchronized", "--value"], capture=True)
    martians_all = run_cmd(["sysctl", "-n", "net.ipv4.conf.all.log_martians"], capture=True)
    martians_default = run_cmd(["sysctl", "-n", "net.ipv4.conf.default.log_martians"], capture=True)

    print(f"log_martians all={martians_all}, default={martians_default}")
    print(f"{SERVICE}: enabled={enabled}, active={active}, ntp_sync={sync_status}")

if __name__ == "__main__":
    if not sys.platform.startswith("linux"):
        sys.exit(1)
    main()
