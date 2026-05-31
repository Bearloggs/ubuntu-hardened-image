#!/bin/bash
# Persistent journal and explicit NTP servers for systemd-timesyncd.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "==> journald and timesyncd..."

sudo mkdir -p /etc/systemd/journald.conf.d
cat <<'EOF' | sudo tee /etc/systemd/journald.conf.d/99-hardening.conf
[Journal]
Storage=persistent
Compress=yes
ForwardToSyslog=no
SystemMaxUse=500M
SystemKeepFree=200M
EOF

sudo mkdir -p /etc/systemd/timesyncd.conf.d
cat <<'EOF' | sudo tee /etc/systemd/timesyncd.conf.d/99-hardening.conf
[Time]
NTP=time.cloudflare.com
FallbackNTP=0.ubuntu.pool.ntp.org 1.ubuntu.pool.ntp.org
EOF

sudo systemctl restart systemd-journald || true
sudo systemctl restart systemd-timesyncd || true

echo "==> journald and timesyncd complete."
