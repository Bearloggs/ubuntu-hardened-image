#!/bin/bash
# AIDE install, optional database init, exclusions, and daily check timer.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if [[ "${INSTALL_AIDE:-true}" != "true" ]]; then
  echo "    Skipping (INSTALL_AIDE=false)"
  exit 0
fi

echo "==> AIDE..."

sudo apt-get install -y aide aide-common

if [[ -f /etc/aide/aide.conf ]]; then
  if ! grep -q '!/snap/' /etc/aide/aide.conf; then
    cat <<'EOF' | sudo tee -a /etc/aide/aide.conf

!/snap/
!/var/snap/
!/var/lib/snapd/
!/run/
!/var/lib/cloud/
!/proc/
!/sys/
!/dev/
EOF
  fi
fi

if [[ "${INITIALIZE_AIDE:-false}" == "true" ]]; then
  echo "    Running aideinit (this may take several minutes)..."
  sudo aideinit || true
  if [[ -f /var/lib/aide/aide.db.new ]]; then
    sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
    sudo chmod 600 /var/lib/aide/aide.db 2>/dev/null || true
  fi
fi

cat <<'EOF' | sudo tee /etc/systemd/system/aide-check.service
[Unit]
Description=AIDE file integrity check
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/aide --check
StandardOutput=journal
StandardError=journal
SyslogIdentifier=aide
User=root
Nice=19
IOSchedulingClass=best-effort
IOSchedulingPriority=7
EOF

cat <<'EOF' | sudo tee /etc/systemd/system/aide-check.timer
[Unit]
Description=Run AIDE check daily

[Timer]
OnCalendar=daily
RandomizedDelaySec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable aide-check.timer
sudo systemctl start aide-check.timer || true

echo "==> AIDE complete."
