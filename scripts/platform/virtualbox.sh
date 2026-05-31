#!/bin/bash
# VirtualBox platform script: installs virtualbox-guest-utils
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "==> Installing virtualbox-guest-utils..."
sudo apt-get update -y
sudo apt-get install -y virtualbox-guest-utils
sudo systemctl enable --now virtualbox-guest-utils || true

echo "==> VirtualBox platform setup complete."
