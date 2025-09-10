#!/bin/bash
# Silent update and upgrade for Ubuntu/Debian

set -euo pipefail

sudo apt update -y >/dev/null 2>&1
sudo apt upgrade -y >/dev/null 2>&1
sudo apt full-upgrade -y >/dev/null 2>&1
sudo apt autoremove -y >/dev/null 2>&1
