#!/bin/bash
# SSH hardening via drop-in (Noble: main sshd_config keeps distro defaults + Include).
set -euo pipefail

echo "==> Hardening SSH configuration (sshd_config.d)..."

sudo mkdir -p /etc/ssh/sshd_config.d

cat <<'EOF' | sudo tee /etc/ssh/sshd_config.d/99-hardening.conf
Port 22

PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
UsePAM yes
PubkeyAuthentication yes
AuthenticationMethods publickey

StrictModes yes
IgnoreRhosts yes
HostbasedAuthentication no
IgnoreUserKnownHosts yes

X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitUserEnvironment no
PermitTunnel no
GatewayPorts no
Compression no
UseDNS no
DebianBanner no
VersionAddendum none

MaxAuthTries 3
MaxSessions 10
LoginGraceTime 30s
MaxStartups 10:30:60

Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com
KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
HostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256
PubkeyAcceptedAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256,sk-ssh-ed25519@openssh.com,sk-ecdsa-sha2-nistp256@openssh.com

SyslogFacility AUTH
LogLevel VERBOSE
PrintLastLog yes
Banner /etc/issue.net
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

cat <<'EOF' | sudo tee /etc/issue.net
***************************************************************************
AUTHORIZED ACCESS ONLY
This system is monitored. Unauthorized access is prohibited.
***************************************************************************
EOF

sudo chmod 644 /etc/ssh/sshd_config.d/99-hardening.conf
sudo chmod 600 /etc/ssh/sshd_config 2>/dev/null || true

sudo sshd -t
sudo systemctl daemon-reload
sudo systemctl restart ssh.socket || sudo systemctl restart ssh || true

echo "==> SSH hardening complete."
