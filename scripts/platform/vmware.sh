#!/bin/bash
# VMware platform script: installs open-vm-tools
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "==> Installing open-vm-tools..."
sudo apt-get update -y
sudo apt-get install -y open-vm-tools
sudo systemctl enable --now open-vm-tools

echo "==> VMware platform setup complete."
