#!/usr/bin/env python3
import fileinput
import sys

duplicates = [
    "-a always,exit -F arch=b64 -S sethostname,setdomainname -k system-locale",
    "-a always,exit -F arch=b32 -S sethostname,setdomainname -k system-locale",
    "-w /etc/issue -p wa -k system-locale",
    "-w /etc/issue.net -p wa -k system-locale",
    "-w /etc/hosts -p wa -k system-locale",
    "-w /etc/networks -p wa -k system-locale",
    "-w /etc/network/ -p wa -k system-locale",
]

file_path = "/etc/audit/rules.d/50-scope.rules"

with open(file_path, "r") as f:
    lines = f.readlines()

with open(file_path, "w") as f:
    for line in lines:
        if line.strip() not in duplicates:
            f.write(line)

print("[OK] Duplicates removed from", file_path)
