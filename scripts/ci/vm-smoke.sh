#!/usr/bin/env bash
# Boot a Hypercube qcow2 headless in QEMU and run smoke checks over SSH.
#
# Usage: vm-smoke.sh <base.qcow2> <ssh-private-key>
#
# The base disk must have been built with the matching public key as root's
# authorized key and sshd enabled (`just ci-disk` does both). It is never
# modified: the VM boots from a throwaway copy-on-write overlay.
#
# Env:
#   VM_MEMORY      MiB of RAM (default 8192)
#   VM_CPUS        vCPUs (default 4)
#   SSH_PORT       host port forwarded to the guest's port 22 (default 2222)
#   BOOT_TIMEOUT   seconds to wait for SSH (default 600; TCG is much slower)
#   VM_KEEP=1      leave the VM running afterwards for debugging
#   ALLOWED_FAILED_UNITS, NIRI_TIMEOUT  forwarded to guest-checks.sh

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <base.qcow2> <ssh-private-key>" >&2
    exit 2
fi

BASE_DISK="$(realpath "$1")"
SSH_KEY="$(realpath "$2")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(dirname "${BASE_DISK}")"

VM_MEMORY="${VM_MEMORY:-8192}"
VM_CPUS="${VM_CPUS:-4}"
SSH_PORT="${SSH_PORT:-2222}"
BOOT_TIMEOUT="${BOOT_TIMEOUT:-600}"
# No NVIDIA GPU in the VM, so NVIDIA's container-toolkit CDI generator fails
# (the live ISO disables it for the same reason).
ALLOWED_FAILED_UNITS="${ALLOWED_FAILED_UNITS:-ublue-nvctk-cdi.service}"
NIRI_TIMEOUT="${NIRI_TIMEOUT:-120}"

OVERLAY="${WORK_DIR}/smoke-overlay.qcow2"
SERIAL_LOG="${WORK_DIR}/serial.log"
PID_FILE="${WORK_DIR}/qemu.pid"

for tool in qemu-system-x86_64 qemu-img ssh; do
    command -v "${tool}" >/dev/null || { echo "Error: ${tool} is not installed" >&2; exit 1; }
done

# --- Firmware: UEFI via OVMF when available, else QEMU's default BIOS ------
# bootc install to-disk --generic-image sets up both, so either boots.
FIRMWARE_ARGS=()
for code in \
    /usr/share/edk2/ovmf/OVMF_CODE.fd \
    /usr/share/OVMF/OVMF_CODE_4M.fd \
    /usr/share/OVMF/OVMF_CODE.fd \
    /usr/share/edk2/x64/OVMF_CODE.4m.fd \
    /usr/share/edk2-ovmf/x64/OVMF_CODE.fd; do
    vars="${code/CODE/VARS}"
    if [[ -f "${code}" && -f "${vars}" ]]; then
        cp "${vars}" "${WORK_DIR}/OVMF_VARS.fd"
        FIRMWARE_ARGS=(
            -drive "if=pflash,format=raw,readonly=on,file=${code}"
            -drive "if=pflash,format=raw,file=${WORK_DIR}/OVMF_VARS.fd"
        )
        echo "Firmware: UEFI (${code})"
        break
    fi
done
((${#FIRMWARE_ARGS[@]})) || echo "Firmware: BIOS (OVMF not found)"

# --- Acceleration ------------------------------------------------------------
ACCEL_ARGS=(-machine q35)
if [[ -w /dev/kvm ]]; then
    ACCEL_ARGS=(-machine "q35,accel=kvm" -cpu host)
    echo "Acceleration: KVM"
else
    echo "Acceleration: TCG (no writable /dev/kvm; this will be slow)"
    BOOT_TIMEOUT=$((BOOT_TIMEOUT * 3))
fi

# --- Boot ----------------------------------------------------------------------
# shellcheck disable=SC2317 # invoked via trap
cleanup() {
    if [[ "${VM_KEEP:-0}" == "1" ]]; then
        echo
        echo "VM left running (VM_KEEP=1). Connect with:"
        echo "  ssh -i ${SSH_KEY} -p ${SSH_PORT} -o StrictHostKeyChecking=no root@localhost"
        echo "Stop it with: kill \$(cat ${PID_FILE})"
        return
    fi
    if [[ -f "${PID_FILE}" ]]; then
        kill "$(cat "${PID_FILE}")" 2>/dev/null || true
        rm -f "${PID_FILE}"
    fi
    rm -f "${OVERLAY}"
}
trap cleanup EXIT

rm -f "${OVERLAY}" "${SERIAL_LOG}"
qemu-img create -q -f qcow2 -F qcow2 -b "${BASE_DISK}" "${OVERLAY}"

# virtio-vga with no display: the guest gets a DRM device with a connected
# virtual output, so niri's normal TTY backend runs on a headless output.
qemu-system-x86_64 \
    "${ACCEL_ARGS[@]}" \
    "${FIRMWARE_ARGS[@]}" \
    -m "${VM_MEMORY}" \
    -smp "${VM_CPUS}" \
    -drive "file=${OVERLAY},format=qcow2,if=virtio" \
    -device virtio-vga \
    -display none \
    -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:${SSH_PORT}-:22" \
    -device virtio-net-pci,netdev=net0 \
    -device virtio-rng-pci \
    -serial "file:${SERIAL_LOG}" \
    -daemonize \
    -pidfile "${PID_FILE}"

SSH_OPTS=(
    -i "${SSH_KEY}"
    -p "${SSH_PORT}"
    -o StrictHostKeyChecking=no
    -o UserKnownHostsFile=/dev/null
    -o LogLevel=ERROR
    -o ConnectTimeout=5
    -o BatchMode=yes
)

echo "Waiting up to ${BOOT_TIMEOUT}s for SSH on localhost:${SSH_PORT} (serial log: ${SERIAL_LOG})..."
deadline=$((SECONDS + BOOT_TIMEOUT))
until ssh "${SSH_OPTS[@]}" root@localhost true 2>/dev/null; do
    if ! kill -0 "$(cat "${PID_FILE}")" 2>/dev/null; then
        echo "Error: QEMU exited early. Last serial output:" >&2
        tail -n 50 "${SERIAL_LOG}" >&2 || true
        exit 1
    fi
    if ((SECONDS >= deadline)); then
        echo "Error: SSH did not come up in ${BOOT_TIMEOUT}s. Last serial output:" >&2
        tail -n 50 "${SERIAL_LOG}" >&2 || true
        exit 1
    fi
    sleep 5
done
echo "SSH is up after ${SECONDS}s"

set +e
# shellcheck disable=SC2029 # expanding these on the host is the point
ssh "${SSH_OPTS[@]}" root@localhost \
    "ALLOWED_FAILED_UNITS='${ALLOWED_FAILED_UNITS}' NIRI_TIMEOUT='${NIRI_TIMEOUT}' bash -s" \
    < "${SCRIPT_DIR}/guest-checks.sh"
status=$?
set -e

if ((status != 0)); then
    echo
    echo "Smoke checks failed. Full serial console log: ${SERIAL_LOG}"
    echo "Re-run with VM_KEEP=1 to keep the VM up and SSH in."
fi
exit "${status}"
