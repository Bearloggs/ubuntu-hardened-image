#!/bin/bash
# Append kernel cmdline once: AppArmor, audit, lockdown (takes effect after reboot / first boot).
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if [[ "${HARDEN_GRUB:-true}" != "true" ]]; then
  echo "    Skipping (HARDEN_GRUB=false)"
  exit 0
fi

echo "==> GRUB kernel parameters (apparmor, audit, lockdown)..."

GRUB_FILE=/etc/default/grub
MARKER="ubuntu-hardened-image-kernel-params"

if ! sudo test -f "${GRUB_FILE}"; then
  echo "    No ${GRUB_FILE}; skipping."
  exit 0
fi

if sudo grep -q "${MARKER}" "${GRUB_FILE}" 2>/dev/null; then
  echo "    GRUB already updated; skipping."
else
  line="$(sudo grep -E '^GRUB_CMDLINE_LINUX_DEFAULT=' "${GRUB_FILE}" | head -1 || true)"
  if [[ -z "${line}" ]]; then
    echo "    No GRUB_CMDLINE_LINUX_DEFAULT= line; skipping."
    exit 0
  fi
  val="${line#GRUB_CMDLINE_LINUX_DEFAULT=}"
  val="${val#\"}"
  val="${val%\"}"
  for token in apparmor=1 security=apparmor audit=1 audit_backlog_limit=8192 lockdown=integrity; do
    if [[ " ${val} " != *" ${token} "* ]]; then
      val="${val} ${token}"
    fi
  done
  tmp="$(mktemp)"
  sudo awk -v newval="${val}" -v m="${MARKER}" '
    /^GRUB_CMDLINE_LINUX_DEFAULT=/ {
      print "GRUB_CMDLINE_LINUX_DEFAULT=\"" newval "\" #" m
      next
    }
    { print }
  ' "${GRUB_FILE}" | sudo tee "${tmp}" >/dev/null
  sudo mv "${tmp}" "${GRUB_FILE}"
fi

if command -v update-grub >/dev/null 2>&1; then
  sudo update-grub
fi

echo "==> GRUB update complete (effective after reboot)."
