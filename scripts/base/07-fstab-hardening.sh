#!/bin/bash
# CIS-style fstab updates with guards for single-root cloud images.
# Typical Canonical EBS images: tmpfs /dev/shm is ensured with noexec,nodev,nosuid.
# Separate ext4/xfs mount points get hardened options when present in fstab.
set -euo pipefail

echo "==> Fstab hardening (guarded)..."

if [[ "${HARDEN_FSTAB:-true}" != "true" ]]; then
  echo "    Skipping (HARDEN_FSTAB=false)"
  exit 0
fi

FSTAB=/etc/fstab
if [[ ! -f "${FSTAB}" ]]; then
  echo "    No ${FSTAB}; skipping."
  exit 0
fi

root_src="$(findmnt -n -o SOURCE / 2>/dev/null || true)"
if [[ -z "${root_src}" ]]; then
  echo "    Could not resolve /; skipping."
  exit 0
fi

tmp_src="$(findmnt -n -o SOURCE /tmp 2>/dev/null || true)"
var_src="$(findmnt -n -o SOURCE /var 2>/dev/null || true)"

append_opts_to_fstab_field4() {
  local mountpoint="$1"
  local extra_csv="$2"
  local tmpfile
  tmpfile="$(mktemp)"
  sudo cp -a "${FSTAB}" "${FSTAB}.bak.packer-fstab"
  sudo awk -v mp="${mountpoint}" -v extras="${extra_csv}" '
    function has(cur, o,   m) {
      m = "," cur ","
      return (index(m, "," o ",") > 0)
    }
    function merged(cur, ex,   e, i, n, out) {
      out = cur
      n = split(ex, e, ",")
      for (i = 1; i <= n; i++) {
        if (e[i] == "") continue
        if (!has(out, e[i])) {
          out = (out == "" ? e[i] : out "," e[i])
        }
      }
      return out
    }
    $2 == mp && ($3 == "ext4" || $3 == "ext3" || $3 == "xfs") { $4 = merged($4, extras) }
    { print }
  ' "${FSTAB}" | sudo tee "${tmpfile}" >/dev/null
  sudo mv "${tmpfile}" "${FSTAB}"
  sudo rm -f "${FSTAB}.bak.packer-fstab"
}

# Never alter the root (/) line here; only separate filesystems listed in fstab.
if [[ -n "${tmp_src}" && "${tmp_src}" != "${root_src}" ]] && grep -qE "[[:space:]]/tmp[[:space:]]+(ext4|ext3|xfs)[[:space:]]" "${FSTAB}"; then
  echo "    Separate /tmp filesystem: adding mount options..."
  append_opts_to_fstab_field4 /tmp "nodev,nosuid,noexec"
fi
if [[ -n "${var_src}" && "${var_src}" != "${root_src}" ]] && grep -qE "[[:space:]]/var[[:space:]]+(ext4|ext3|xfs)[[:space:]]" "${FSTAB}"; then
  echo "    Separate /var filesystem: adding mount options..."
  append_opts_to_fstab_field4 /var "nodev,nosuid"
fi
if grep -qE "[[:space:]]/var/tmp[[:space:]]+(ext4|ext3|xfs)[[:space:]]" "${FSTAB}"; then
  append_opts_to_fstab_field4 /var/tmp "nodev,nosuid,noexec"
fi
if grep -qE "[[:space:]]/var/log[[:space:]]+(ext4|ext3|xfs)[[:space:]]" "${FSTAB}"; then
  append_opts_to_fstab_field4 /var/log "nodev,nosuid,noexec"
fi
if grep -qE "[[:space:]]/var/log/audit[[:space:]]+(ext4|ext3|xfs)[[:space:]]" "${FSTAB}"; then
  append_opts_to_fstab_field4 /var/log/audit "nodev,nosuid,noexec"
fi

# /dev/shm tmpfs: ensure hardened options without duplicating the line.
if grep -qE '^[[:space:]]*tmpfs[[:space:]]+/dev/shm[[:space:]]' "${FSTAB}"; then
  if ! grep -E '^[[:space:]]*tmpfs[[:space:]]+/dev/shm[[:space:]]' "${FSTAB}" | grep -q noexec; then
    echo "    Setting tmpfs /dev/shm mount options..."
    tmpfile="$(mktemp)"
    sudo awk '
      /^[[:space:]]*tmpfs[[:space:]]+\/dev\/shm[[:space:]]+tmpfs/ { $4 = "defaults,noexec,nodev,nosuid" }
      { print }
    ' "${FSTAB}" | sudo tee "${tmpfile}" >/dev/null
    sudo mv "${tmpfile}" "${FSTAB}"
  fi
else
  if ! grep -qE '[[:space:]]/dev/shm[[:space:]]' "${FSTAB}"; then
    echo "    Appending tmpfs /dev/shm entry..."
    echo 'tmpfs /dev/shm tmpfs defaults,noexec,nodev,nosuid 0 0' | sudo tee -a "${FSTAB}" >/dev/null
  fi
fi

echo "==> Fstab hardening complete."
