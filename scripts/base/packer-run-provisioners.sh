#!/bin/bash
# Run numbered hardening scripts in order (shared by AWS and other Packer builders).
# Environment is inherited from the Packer shell provisioner (see packer/_shared/locals.pkr.hcl).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
run() {
  echo "==> ${1}"
  bash "${ROOT}/${1}"
}
run 00-wait-cloudinit.sh
run 01-update.sh
run 02-hardening.sh
run 02b-modprobe-blacklist.sh
run 02c-apparmor.sh
run 02d-pam-accounts.sh
run 03-ssh-hardening.sh
run 04-kernel-hardening.sh
run 04b-grub-hardening.sh
run 05-audit.sh
run 05b-aide.sh
run 05d-systemd-sandbox.sh
run 05e-journald-time.sh
run 07-fstab-hardening.sh
echo "==> packer-run-provisioners.sh finished."
