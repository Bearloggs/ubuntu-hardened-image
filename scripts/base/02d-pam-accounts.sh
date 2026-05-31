#!/bin/bash
# PAM faillock, pwhistory, login.defs, pwquality, and unused account hardening.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "==> PAM and account hardening..."

sudo apt-get install -y \
  libpam-pwquality \
  libpam-faillock \
  libpam-modules \
  libpam-modules-bin

cat <<'EOF' | sudo tee /etc/security/faillock.conf
deny = 5
unlock_time = 900
fail_interval = 900
EOF

if [[ -f /usr/share/pam-configs/faillock ]]; then
  DEBIAN_FRONTEND=noninteractive sudo pam-auth-update --enable faillock --force || true
fi

if [[ -f /usr/share/pam-configs/pwhistory ]]; then
  DEBIAN_FRONTEND=noninteractive sudo pam-auth-update --enable pwhistory --force || true
fi

if [[ -f /etc/security/pwhistory.conf ]]; then
  if grep -q '^#*remember' /etc/security/pwhistory.conf; then
    sudo sed -i 's/^#*remember *=.*/remember = 5/' /etc/security/pwhistory.conf
  else
    echo 'remember = 5' | sudo tee -a /etc/security/pwhistory.conf >/dev/null
  fi
fi

if ! grep -qE '^password[[:space:]].*pam_pwhistory\.so' /etc/pam.d/common-password 2>/dev/null; then
  tmp="$(mktemp)"
  {
    echo 'password required pam_pwhistory.so remember=5 use_authtok retry=3'
    sudo cat /etc/pam.d/common-password
  } >"${tmp}"
  sudo mv "${tmp}" /etc/pam.d/common-password
  sudo chmod 644 /etc/pam.d/common-password
fi

cat <<'EOF' | sudo tee /etc/security/pwquality.conf
minlen = 14
dcredit = -1
ucredit = -1
ocredit = -1
lcredit = -1
maxrepeat = 3
EOF

sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS\t90/' /etc/login.defs
sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS\t1/' /etc/login.defs
sudo sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE\t7/' /etc/login.defs
sudo sed -i 's/^UMASK.*/UMASK\t027/' /etc/login.defs
if grep -qE '^#*ENCRYPT_METHOD' /etc/login.defs; then
  sudo sed -i 's/^#*ENCRYPT_METHOD.*/ENCRYPT_METHOD\tSHA512/' /etc/login.defs
else
  echo 'ENCRYPT_METHOD SHA512' | sudo tee -a /etc/login.defs >/dev/null
fi
if grep -qE '^#*SHA_CRYPT_MIN_ROUNDS' /etc/login.defs; then
  sudo sed -i 's/^#*SHA_CRYPT_MIN_ROUNDS.*/SHA_CRYPT_MIN_ROUNDS\t5000/' /etc/login.defs
else
  echo 'SHA_CRYPT_MIN_ROUNDS 5000' | sudo tee -a /etc/login.defs >/dev/null
fi

echo "==> Locking unused system accounts (omit www-data)..."
for user in games news uucp proxy backup list irc gnats; do
  if id "$user" &>/dev/null; then
    sudo passwd -l "$user" 2>/dev/null || true
    sudo usermod -s /usr/sbin/nologin "$user" 2>/dev/null || true
    sudo chage -E 0 "$user" 2>/dev/null || true
    echo "  Locked: $user"
  fi
done

echo "==> PAM and account hardening complete."
