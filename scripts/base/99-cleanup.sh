#!/bin/bash
# Final image cleanup: logs, caches, identifiers, SSH host keys.
set -euo pipefail

echo "==> Cleaning build artifacts..."

sudo journalctl --rotate 2>/dev/null || true
sudo journalctl --vacuum-time=1s 2>/dev/null || true

sudo apt-get autoremove -y
sudo apt-get autoclean -y
sudo rm -rf /var/lib/apt/lists/*

sudo systemd-tmpfiles --clean 2>/dev/null || true
sudo systemd-tmpfiles --remove 2>/dev/null || true

sudo find /var/cache -type f -exec rm -f {} + 2>/dev/null || true

sudo rm -rf /tmp/* /var/tmp/* 2>/dev/null || true

sudo truncate -s 0 /var/log/*.log 2>/dev/null || true
sudo find /var/log -type f -name '*.log' -exec truncate -s 0 {} + 2>/dev/null || true
sudo find /var/log -type f ! -name '*.log' -size +0 -exec truncate -s 0 {} + 2>/dev/null || true

sudo rm -f /root/.bash_history
rm -f "${HOME}/.bash_history" || true
history -c || true

sudo rm -f /root/.wget-hsts

# Golden-AMI hygiene: unique IDs and seeds regenerate on first boot / cloud-init.
if [[ -f /etc/machine-id ]]; then
  sudo truncate -s 0 /etc/machine-id
fi
sudo rm -f /var/lib/dbus/machine-id
sudo ln -sf /etc/machine-id /var/lib/dbus/machine-id

sudo rm -f /var/lib/systemd/random-seed
if [[ -f /loader/random-seed ]]; then
  sudo rm -f /loader/random-seed
fi
if [[ -f /etc/machine-info ]]; then
  sudo rm -f /etc/machine-info
fi

if [[ "${CLEAR_CLOUDINIT_SUDOERS:-false}" == "true" ]]; then
  sudo rm -f /etc/sudoers.d/90-cloud-init-users
fi

sudo cloud-init clean --logs

# Remove baked host keys; first boot / cloud-init regenerates them on the AMI
sudo rm -f /etc/ssh/ssh_host_*

# Remove Packer bootstrap authorized_keys (amazon-ebs clears via builder; generic disks need this)
build_user="${BUILD_SSH_USERNAME:-ubuntu}"
auth_keys="/home/${build_user}/.ssh/authorized_keys"
if [[ -f "${auth_keys}" ]]; then
  sudo rm -f "${auth_keys}"
fi

echo "==> Cleanup complete."
