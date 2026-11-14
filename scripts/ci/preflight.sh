#!/usr/bin/env bash
# Check that this machine (your laptop or a CI runner) can run `just ci`:
# build the image, install it to a disk with bootc, and boot it in QEMU.
# Run it with `just ci-preflight`; `just ci` runs it first. It prints what it
# finds and exits non-zero only for things that would make `just ci` fail.
#
# The space and memory thresholds are estimates. If a run still dies for
# space or memory, raise them here.
#
# Env: VM_MEMORY (MiB, default 8192, same as vm-smoke.sh), MIN_DISK_GB
# (default 50), WARN_DISK_GB (default 80), REQUIRE_KVM=1 to fail instead of
# warn without KVM (CI sets it: under TCG the boot is too slow to be useful).

set -uo pipefail

VM_MEMORY="${VM_MEMORY:-8192}"
MIN_DISK_GB="${MIN_DISK_GB:-50}"
WARN_DISK_GB="${WARN_DISK_GB:-80}"
REQUIRE_KVM="${REQUIRE_KVM:-0}"

errors=0
warnings=0
ok() { echo "  ok    $*"; }
warn() { echo "  WARN  $*"; warnings=$((warnings + 1)); }
kvm_problem() { if [[ "${REQUIRE_KVM}" == "1" ]]; then err "$*"; else warn "$*"; fi; }
err() { echo "  FAIL  $*"; errors=$((errors + 1)); }

is_root=0
[[ "$(id -u)" -eq 0 ]] && is_root=1
as_root() { if ((is_root)); then "$@"; else sudo -n "$@"; fi; }

echo "Host: $(uname -srm), $(nproc) CPUs, running as $(id -un)"

echo
echo "Tools"
for tool in podman qemu-system-x86_64 qemu-img; do
    if command -v "${tool}" >/dev/null; then
        ok "${tool}: $("${tool}" --version 2>/dev/null | head -1)"
    else
        err "${tool} is not installed"
    fi
done
for tool in ssh ssh-keygen; do
    if command -v "${tool}" >/dev/null; then
        ok "${tool}: $(ssh -V 2>&1 | head -1)"
    else
        err "${tool} is not installed (openssh-client)"
    fi
done
if ((!is_root)); then
    if command -v sudo >/dev/null; then
        ok "sudo is available (bootc install runs rootful; you may be prompted)"
    else
        err "not root and sudo is missing; bootc install needs root"
    fi
fi

echo
echo "Virtualization"
if [[ -e /dev/kvm ]]; then
    if [[ -r /dev/kvm && -w /dev/kvm ]]; then
        ok "/dev/kvm is usable"
    elif ((is_root)); then
        ok "/dev/kvm exists (root can use it)"
    else
        kvm_problem "/dev/kvm exists but $(id -un) can't use it; add yourself to the kvm group, or the VM falls back to slow TCG emulation"
    fi
else
    if grep -qE 'vmx|svm' /proc/cpuinfo; then
        kvm_problem "/dev/kvm missing though the CPU supports virtualization; load kvm_intel/kvm_amd. Without it the VM uses TCG and the boot can take 10x longer"
    else
        kvm_problem "no /dev/kvm and no vmx/svm CPU flags (no nested virtualization on this host?). The VM will use slow TCG emulation"
    fi
fi
ovmf=""
for f in /usr/share/edk2/ovmf/OVMF_CODE.fd /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd \
    /usr/share/edk2/x64/OVMF_CODE.4m.fd /usr/share/edk2-ovmf/x64/OVMF_CODE.fd; do
    [[ -f "${f}" ]] && { ovmf="${f}"; break; }
done
if [[ -n "${ovmf}" ]]; then
    ok "OVMF (UEFI firmware): ${ovmf}"
else
    warn "OVMF not found; the VM boots with legacy BIOS instead of UEFI (install edk2-ovmf / ovmf)"
fi

echo
echo "Kernel features used by bootc install"
if [[ -e /dev/loop-control ]]; then
    ok "loop devices (/dev/loop-control)"
else
    err "no /dev/loop-control; bootc install --via-loopback needs loop devices (modprobe loop)"
fi
if grep -qw btrfs /proc/filesystems || modinfo btrfs &>/dev/null; then
    ok "btrfs (the disk is formatted btrfs)"
else
    err "this kernel has no btrfs support; bootc install --filesystem btrfs can't mount the disk"
fi

echo
echo "Memory"
mem_mib=$(($(awk '/^MemTotal:/ {print $2}' /proc/meminfo) / 1024))
need_mib=$((VM_MEMORY + 2048))
if ((mem_mib >= need_mib)); then
    ok "${mem_mib} MiB RAM (VM uses ${VM_MEMORY} MiB)"
else
    err "${mem_mib} MiB RAM; the VM alone wants ${VM_MEMORY} MiB. Lower VM_MEMORY (e.g. VM_MEMORY=4096) or use a bigger machine"
fi

echo
echo "Disk space (image build + bootc install + qcow2 conversion)"
# Root's podman storage is where bootc install reads the image from; the
# repo's .vm/ holds the raw disk while it is converted to qcow2.
graphroot="$(as_root podman info --format '{{.Store.GraphRoot}}' 2>/dev/null)"
[[ -z "${graphroot}" ]] && graphroot=/var/lib/containers/storage
check_space() {
    local label="$1" path="$2" probe avail_gb
    probe="${path}"
    while [[ ! -e "${probe}" ]]; do probe="$(dirname "${probe}")"; done
    avail_gb=$(df -P -BG "${probe}" | awk 'NR==2 {gsub("G","",$4); print $4}')
    local mount
    mount=$(df -P "${probe}" | awk 'NR==2 {print $6}')
    echo "${mount} ${avail_gb} ${label}"
}
mapfile -t space < <( { check_space "podman storage (${graphroot})" "${graphroot}"; check_space "repo (.vm/)" "${PWD}/.vm"; } | sort -u -k1,1)
for line in "${space[@]}"; do
    read -r mount avail_gb label <<<"${line}"
    if ((avail_gb < MIN_DISK_GB)); then
        err "${avail_gb} GB free on ${mount} (${label}); need about ${MIN_DISK_GB} GB"
    elif ((avail_gb < WARN_DISK_GB)); then
        warn "${avail_gb} GB free on ${mount} (${label}); a full run may need up to ~${WARN_DISK_GB} GB if storage and .vm/ share this disk"
    else
        ok "${avail_gb} GB free on ${mount} (${label})"
    fi
done

echo
if ((errors > 0)); then
    echo "${errors} problem(s) will stop \`just ci\`; fix them first. (${warnings} warning(s))"
    exit 1
fi
echo "Ready for \`just ci\` (${warnings} warning(s))"
