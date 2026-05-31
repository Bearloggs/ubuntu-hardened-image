#!/bin/bash
set -euo pipefail

echo "==> Updating system packages..."
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get autoremove -y
sudo apt-get autoclean -y

echo "==> Installing baseline security packages..."
sudo apt-get install -y \
  auditd \
  ufw \
  unattended-upgrades \
  apt-listchanges \
  libpam-pwquality \
  acl \
  apparmor \
  apparmor-utils \
  apparmor-profiles \
  apparmor-profiles-extra \
  libpam-faillock \
  needrestart \
  debsums \
  rkhunter \
  lynis
