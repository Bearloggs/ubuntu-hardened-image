#!/bin/bash
# AppArmor install and selective profile enforcement (cloud-server safe).
# Kernel cmdline apparmor=1 is applied in 04b-grub-hardening.sh (single update-grub).
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if [[ "${ENABLE_APPARMOR:-true}" != "true" ]]; then
  echo "    Skipping (ENABLE_APPARMOR=false)"
  exit 0
fi

echo "==> AppArmor..."

sudo apt-get install -y \
  apparmor \
  apparmor-utils \
  apparmor-profiles \
  apparmor-profiles-extra

sudo systemctl enable --now apparmor

for profile in usr.sbin.sshd usr.sbin.cron usr.sbin.rsyslogd; do
  if [[ -f "/etc/apparmor.d/${profile}" ]]; then
    sudo aa-enforce "/etc/apparmor.d/${profile}" 2>/dev/null || true
    echo "    Enforced: ${profile}"
  fi
done

echo "==> AppArmor complete."
