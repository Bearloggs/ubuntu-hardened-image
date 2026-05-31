#!/bin/bash
# Systemd sandbox drop-in for ssh only.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if [[ "${HARDEN_SYSTEMD_SERVICES:-true}" != "true" ]]; then
  echo "    Skipping (HARDEN_SYSTEMD_SERVICES=false)"
  exit 0
fi

echo "==> Systemd service sandboxing (ssh)..."

sudo mkdir -p /etc/systemd/system/ssh.service.d
cat <<'EOF' | sudo tee /etc/systemd/system/ssh.service.d/hardening.conf
[Service]
ProtectSystem=strict
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectKernelLogs=yes
ProtectControlGroups=yes
RestrictNamespaces=yes
RestrictRealtime=yes
RestrictSUIDSGID=yes
LockPersonality=yes
NoNewPrivileges=yes
SystemCallArchitectures=native
MemoryDenyWriteExecute=yes
EOF

sudo systemctl daemon-reload

echo "==> Systemd sandboxing complete (restart units on next boot or manually)."
