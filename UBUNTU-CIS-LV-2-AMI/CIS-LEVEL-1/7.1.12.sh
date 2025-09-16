#!/bin/bash
set -euo pipefail

# CIS 7.1.12: Ensure no files or directories without an owner and a group exist
# Remediation: assign root:root to orphaned files/directories

# Find files without a valid owner and change to root:root
find / -xdev -nouser -type f -exec chown root:root {} + 2>/dev/null || true

# Find directories without a valid owner and change to root:root
find / -xdev -nouser -type d -exec chown root:root {} + 2>/dev/null || true

# Find files without a valid group and change to root:root
find / -xdev -nogroup -type f -exec chown root:root {} + 2>/dev/null || true

# Find directories without a valid group and change to root:root
find / -xdev -nogroup -type d -exec chown root:root {} + 2>/dev/null || true
