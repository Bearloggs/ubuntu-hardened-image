#!/bin/bash
# CIS-style filesystem and protocol module blacklist (Noble server baseline).
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if [[ "${HARDEN_MODULES:-true}" != "true" ]]; then
  echo "    Skipping (HARDEN_MODULES=false)"
  exit 0
fi

echo "==> Modprobe blacklist (CIS-style)..."

cat <<'EOF' | sudo tee /etc/modprobe.d/cis-blacklist.conf
install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install udf /bin/true
install usb-storage /bin/true
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
install firewire-core /bin/true
EOF

sudo update-initramfs -u -k all

echo "==> Modprobe blacklist complete."
