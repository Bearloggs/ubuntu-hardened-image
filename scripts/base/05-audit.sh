#!/bin/bash
set -euo pipefail

echo "==> Configuring auditd..."

AUDITD=/etc/audit/auditd.conf
if [[ -f "${AUDITD}" ]]; then
  _patch_auditd() {
    local k="$1"
    local v="$2"
    sudo sed -i "/^[#[:space:]]*${k}[[:space:]]*=/d" "${AUDITD}"
    echo "${k} = ${v}" | sudo tee -a "${AUDITD}" >/dev/null
  }
  _patch_auditd log_format ENRICHED
  _patch_auditd max_log_file 8
  _patch_auditd num_logs 5
  _patch_auditd space_left_action SYSLOG
  _patch_auditd admin_space_left_action SUSPEND
  _patch_auditd disk_full_action SUSPEND
  _patch_auditd disk_error_action SUSPEND
fi

cat <<'EOF' | sudo tee /etc/logrotate.d/audit-hardening
/var/log/audit/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0600 root root
    sharedscripts
    postrotate
        /usr/bin/systemctl kill -s USR1 auditd.service >/dev/null 2>&1 || true
    endscript
}
EOF

cat <<'EOF' | sudo tee /etc/audit/rules.d/99-hardening.rules
-D
-b 8192
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers
-w /etc/ssh/sshd_config -p wa -k sshd
-w /etc/ssh/sshd_config.d/ -p wa -k sshd
-w /etc/apparmor.d/ -p wa -k apparmor
-w /etc/apparmor/ -p wa -k apparmor
-w /etc/systemd/ -p wa -k systemd
-w /lib/systemd/ -p wa -k systemd
-w /etc/netplan/ -p wa -k network_config
-w /etc/cron.allow -p wa -k cron
-w /etc/cron.deny -p wa -k cron
-w /etc/cron.d/ -p wa -k cron
-w /etc/cron.daily/ -p wa -k cron
-w /etc/cron.hourly/ -p wa -k cron
-w /etc/cron.monthly/ -p wa -k cron
-w /etc/cron.weekly/ -p wa -k cron
-w /etc/crontab -p wa -k cron
-w /var/spool/cron/ -p wa -k cron
-w /var/log/faillog -p wa -k logins
-w /var/log/lastlog -p wa -k logins
-w /var/run/faillock/ -p wa -k logins
-a always,exit -F arch=b64 -S execve -k exec
-a always,exit -F arch=b64 -S open,creat,truncate -F exit=-EACCES -k access
-a always,exit -F arch=b64 -S chmod,fchmod,fchmodat -k chmod
-a always,exit -F arch=b64 -S chown,fchown,lchown,fchownat -k chown
-a always,exit -F arch=b64 -S init_module,finit_module -k modules
-a always,exit -F arch=b64 -S delete_module -k modules
-a always,exit -F arch=b64 -S adjtimex,settimeofday,clock_settime -k time-change
-a always,exit -F arch=b32 -S adjtimex,settimeofday,clock_settime -k time-change
-a always,exit -F arch=b64 -S sethostname,setdomainname -k system-locale
-a always,exit -F path=/usr/bin/passwd -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/su -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/bin/chage -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged
-a always,exit -F path=/usr/sbin/usermod -F perm=x -F auid>=1000 -F auid!=4294967295 -k privileged
-a always,exit -F arch=b64 -S connect -k network
-e 2
EOF

sudo augenrules --load 2>/dev/null || true
sudo systemctl enable auditd
sudo systemctl restart auditd || sudo systemctl start auditd
echo "==> auditd configured."
