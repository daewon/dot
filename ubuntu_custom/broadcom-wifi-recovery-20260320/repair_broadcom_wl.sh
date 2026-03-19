#!/usr/bin/env bash
set -euo pipefail

PATCHSET_REPO="${PATCHSET_REPO:-https://git.launchpad.net/ubuntu/+source/broadcom-sta}"
PATCHSET_COMMIT="${PATCHSET_COMMIT:-84a67de558f3c0e82154cc4631195bf85559e7c1}"
PATCHSET_VERSION="${PATCHSET_VERSION:-6.30.223.271-23ubuntu1.2}"
SOURCE_VERSION="${SOURCE_VERSION:-6.30.223.271}"
WORKDIR="${WORKDIR:-/tmp/broadcom-sta-recovery}"
SOURCE_DIR="/usr/src/broadcom-sta-${SOURCE_VERSION}"
PATCHED_DIR="${WORKDIR}/broadcom-sta-git/amd64"
KVER="$(uname -r)"

cleanup() {
  rm -rf "${WORKDIR}"
}

log() {
  printf '[broadcom-wifi] %s\n' "$*"
}

die() {
  printf '[broadcom-wifi] ERROR: %s\n' "$*" >&2
  exit 1
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    die "Run as root: sudo ./repair_broadcom_wl.sh"
  fi
}

find_active_wifi_connection() {
  nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2=="802-11-wireless"{print $1; exit}'
}

find_wifi_device() {
  nmcli -t -f DEVICE,TYPE device status 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}'
}

copy_patched_files() {
  local rel
  local files=(
    Makefile
    src/include/linuxver.h
    src/wl/sys/wl_linux.c
    src/wl/sys/wl_cfg80211_hybrid.c
    src/include/bcmutils.h
    src/include/wlioctl.h
    src/wl/sys/wl_cfg80211_hybrid.h
    src/wl/sys/wl_iw.c
  )

  for rel in "${files[@]}"; do
    [[ -f "${PATCHED_DIR}/${rel}" ]] || die "Missing patched file: ${PATCHED_DIR}/${rel}"
    [[ -f "${SOURCE_DIR}/${rel}" ]] || die "Missing local source file: ${SOURCE_DIR}/${rel}"
    install -D -m 0644 "${PATCHED_DIR}/${rel}" "${SOURCE_DIR}/${rel}"
  done
}

require_root
trap cleanup EXIT

log "Target kernel: ${KVER}"

if dpkg-query -W -f='${Version}\n' broadcom-sta-dkms >/dev/null 2>&1; then
  installed_pkg_version="$(dpkg-query -W -f='${Version}\n' broadcom-sta-dkms)"
  log "Installed broadcom-sta-dkms version: ${installed_pkg_version}"
  if dpkg --compare-versions "${installed_pkg_version}" ge "${PATCHSET_VERSION}" && [[ "${FORCE:-0}" != "1" ]]; then
    die "Installed package is already ${installed_pkg_version}. This script targets ${PATCHSET_VERSION} patchset or older. Use FORCE=1 only if you verified the package is still broken."
  fi
fi

export DEBIAN_FRONTEND=noninteractive
log "Installing prerequisites and broadcom-sta-dkms"
set +e
apt-get update
apt-get install -y git dkms broadcom-sta-dkms
apt_rc=$?
set -e
if [[ "${apt_rc}" -ne 0 ]]; then
  log "apt-get returned ${apt_rc}; continuing because broadcom-sta-dkms 23ubuntu1.1 is expected to fail on Linux 6.17 before patching"
fi

[[ -d "${SOURCE_DIR}" ]] || die "Expected source directory not found: ${SOURCE_DIR}"

log "Fetching Ubuntu patched source at commit ${PATCHSET_COMMIT}"
rm -rf "${WORKDIR}"
git clone "${PATCHSET_REPO}" "${WORKDIR}/broadcom-sta-git"
git -C "${WORKDIR}/broadcom-sta-git" checkout "${PATCHSET_COMMIT}"

log "Copying patched amd64 source files into ${SOURCE_DIR}"
copy_patched_files

log "Rebuilding DKMS module for kernel ${KVER}"
rm -rf "/var/lib/dkms/broadcom-sta/${SOURCE_VERSION}/build"
dkms build -m broadcom-sta -v "${SOURCE_VERSION}" -k "${KVER}" --force
dkms install -m broadcom-sta -v "${SOURCE_VERSION}" -k "${KVER}" --force
depmod -a "${KVER}"
dpkg --configure -a

wifi_conn="$(find_active_wifi_connection || true)"

log "Switching kernel modules to wl"
modprobe -r brcmsmac 2>/dev/null || true
modprobe -r b43 2>/dev/null || true
modprobe -r ssb 2>/dev/null || true
modprobe -r bcma 2>/dev/null || true
modprobe wl

wifi_dev="$(find_wifi_device || true)"
if [[ -n "${wifi_conn}" ]]; then
  log "Disabling Wi-Fi powersave on connection: ${wifi_conn}"
  nmcli connection modify "${wifi_conn}" 802-11-wireless.powersave 2 || true
fi
if [[ -n "${wifi_conn}" && -n "${wifi_dev}" ]]; then
  log "Reactivating Wi-Fi connection ${wifi_conn} on ${wifi_dev}"
  nmcli connection up "${wifi_conn}" ifname "${wifi_dev}" || true
fi

wifi_dev="$(find_wifi_device || true)"
gateway=""
if [[ -n "${wifi_dev}" ]]; then
  gateway="$(nmcli -g IP4.GATEWAY device show "${wifi_dev}" 2>/dev/null | sed -n '1p')"
fi

log "Verification summary"
lsmod | grep -E '^(wl|brcmsmac|b43|ssb|bcma)\b' || true
dkms status | sed -n '1,20p'
nmcli device status || true
if [[ -n "${wifi_dev}" ]]; then
  iwconfig "${wifi_dev}" || true
fi
if [[ -n "${gateway}" ]]; then
  ping -c 4 "${gateway}" || true
fi
ping -c 4 1.1.1.1 || true

log "Done"
