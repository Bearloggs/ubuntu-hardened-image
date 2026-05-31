#!/bin/bash
set -euo pipefail

echo "==> Applying system hardening..."

# ---------------------------------------------------------------------------
# 1. Stop and disable unneeded services if present
# ---------------------------------------------------------------------------
SERVICES_TO_DISABLE=(
  "avahi-daemon"
  "cups"
  "isc-dhcp-server"
  "slapd"
  "nfs-server"
  "rpcbind"
  "bind9"
  "vsftpd"
  "apache2"
  "dovecot"
  "samba"
  "squid"
  "snmpd"
)

for service in "${SERVICES_TO_DISABLE[@]}"; do
  if systemctl is-active --quiet "$service" 2>/dev/null; then
    sudo systemctl stop "$service"
    sudo systemctl disable "$service"
    echo "  Disabled: $service"
  fi
done

if systemctl list-unit-files 2>/dev/null | grep -qE '^atd\.service'; then
  sudo systemctl mask atd --now 2>/dev/null || true
  echo "  Masked: atd"
fi

# ---------------------------------------------------------------------------
# 2. UFW firewall
# ---------------------------------------------------------------------------
echo "==> Configuring UFW..."
if [[ -f /etc/default/ufw ]]; then
  sudo sed -i 's/^IPV6=.*/IPV6=yes/' /etc/default/ufw
fi
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw logging medium
sudo ufw limit 22/tcp comment 'SSH rate limit'
sudo ufw allow 68/udp comment 'DHCP client' 2>/dev/null || true
sudo ufw --force enable

cat <<'EOF' | sudo tee /etc/logrotate.d/ufw-hardening
/var/log/ufw.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
    sharedscripts
    postrotate
        systemctl reload rsyslog >/dev/null 2>&1 || true
    endscript
}
EOF

# ---------------------------------------------------------------------------
# 3. Unattended security upgrades
# ---------------------------------------------------------------------------
echo "==> Configuring unattended upgrades..."
cat <<'EOF' | sudo tee /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

# ---------------------------------------------------------------------------
# 4. Permissions on sensitive files
# ---------------------------------------------------------------------------
echo "==> Setting file permissions..."
sudo chmod 600 /etc/ssh/sshd_config 2>/dev/null || true
sudo find /etc/ssh/sshd_config.d -type f -name '*.conf' -exec chmod 644 {} + 2>/dev/null || true
sudo chmod 644 /etc/passwd
sudo chmod 640 /etc/shadow
sudo chmod 644 /etc/group
sudo chmod 640 /etc/gshadow

sudo touch /etc/cron.allow 2>/dev/null || true
sudo chmod 600 /etc/cron.allow 2>/dev/null || true
if [[ -d /etc/cron.d ]]; then
  sudo chmod 700 /etc/cron.d
fi
sudo chmod 640 /etc/at.deny 2>/dev/null || true
sudo chmod 640 /etc/at.allow 2>/dev/null || true

# PAM, pwquality, faillock, login.defs, and unused accounts: scripts/02d-pam-accounts.sh
