#!/bin/bash
# Proxmox platform script: installs qemu-guest-agent
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "==> Installing qemu-guest-agent..."
sudo apt-get update -y
sudo apt-get install -y qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent

echo "==> Proxmox platform setup complete."
