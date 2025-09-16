#!/usr/bin/env python3
import os
import stat
import subprocess

def fix_audit_file_permissions():
    audit_dir = "/etc/audit"
    success = True
    fixed_files = []

    for root, _, files in os.walk(audit_dir):
        for fname in files:
            if fname.endswith(".conf") or fname.endswith(".rules"):
                fpath = os.path.join(root, fname)
                try:
                    # Set mode to 0640
                    os.chmod(fpath, 0o640)
                    fixed_files.append(fpath)

                    # Verify mode
                    st = os.stat(fpath)
                    if stat.S_IMODE(st.st_mode) != 0o640:
                        success = False
                except Exception as e:
                    print(f"[ERROR] Could not fix {fpath}: {e}")
                    success = False

    if success:
        print("✅ CIS 6.2.4.5 remediation successful: All audit configuration files set to 0640")
    else:
        print("❌ CIS 6.2.4.5 remediation failed: Some files did not get corrected")

if __name__ == "__main__":
    fix_audit_file_permissions()
