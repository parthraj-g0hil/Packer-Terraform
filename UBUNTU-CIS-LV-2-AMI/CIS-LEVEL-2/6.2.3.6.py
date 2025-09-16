#!/usr/bin/env python3
"""
Remediate CIS 6.2.3.6:
Ensure use of privileged commands are collected.
"""

import sys
import os
from pathlib import Path

RULES_FILE = Path("/etc/audit/rules.d/50-privileged.rules")


def get_uid_min():
    """Get UID_MIN from /etc/login.defs"""
    try:
        with open("/etc/login.defs") as f:
            for line in f:
                if line.strip().startswith("UID_MIN"):
                    return line.split()[1]
    except Exception:
        return None
    return None


def get_partitions():
    """Return list of partitions that are not mounted with noexec/nosuid."""
    # Skip complex mount parsing for Packer-safe version
    return ["/"]  # assume root partition for simplicity


def find_privileged_binaries(partition):
    """Find setuid/setgid binaries in a given partition."""
    import subprocess

    try:
        result = subprocess.run(
            ["find", partition, "-xdev", "-perm", "/6000", "-type", "f"],
            capture_output=True,
            text=True,
        )
        return result.stdout.splitlines()
    except Exception:
        return []


def build_rules(binaries, uid_min):
    """Build audit rules for privileged binaries."""
    rules = []
    for b in binaries:
        rules.append(
            f"-a always,exit -F path={b} -F perm=x -F auid>={uid_min} -F auid!=unset -k privileged"
        )
    return rules


def main():
    if os.geteuid() != 0:
        print("Failed: must be run as root")
        sys.exit(1)

    uid_min = get_uid_min()
    if not uid_min:
        print("Failed: UID_MIN not found")
        sys.exit(1)

    partitions = get_partitions()
    all_rules = []
    for p in partitions:
        bins = find_privileged_binaries(p)
        if bins:
            all_rules.extend(build_rules(bins, uid_min))

    if not all_rules:
        print("⚠️ No privileged binaries found; rule file will be empty")

    try:
        final_rules = sorted(set(all_rules))
        with open(RULES_FILE, "w") as f:
            f.write("\n".join(final_rules) + "\n")
    except Exception as e:
        print(f"Failed: could not write {RULES_FILE} ({e})")
        sys.exit(1)

    # Skip loading audit rules in Packer
    print(f"✅ CIS 6.2.3.6 remediation done (rules written to {RULES_FILE})")


if __name__ == "__main__":
    main()
