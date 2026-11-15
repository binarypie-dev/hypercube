#!/usr/bin/env bash
# Install a bootc container image onto a fresh qcow2 disk with
# `bootc install to-disk`, run from inside the image itself.
#
# Usage: bootc-to-qcow2.sh <image> <output.qcow2> [extra bootc install args...]
#
# The image must already be in root podman storage (bootc install runs in a
# rootful, privileged container). Extra args are passed straight to
# `bootc install to-disk`; paths they reference must be under /output, which
# is the directory holding <output.qcow2>.
#
# Env: DISK_SIZE (default 64G), SUDO (default sudo unless root), PODMAN.

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "usage: $0 <image> <output.qcow2> [bootc install args...]" >&2
    exit 2
fi

IMAGE="$1"
QCOW2_FILE="$(realpath -m "$2")"
shift 2

DISK_SIZE="${DISK_SIZE:-64G}"
PODMAN="${PODMAN:-podman}"
if [[ -z "${SUDO+x}" ]]; then
    if [[ "$(id -u)" -eq 0 ]]; then SUDO=""; else SUDO="sudo"; fi
fi

OUTPUT_DIR="$(dirname "${QCOW2_FILE}")"
RAW_FILE="${QCOW2_FILE%.qcow2}.raw"
mkdir -p "${OUTPUT_DIR}"
rm -f "${RAW_FILE}" "${QCOW2_FILE}"

echo "Creating ${DISK_SIZE} raw disk image..."
truncate -s "${DISK_SIZE}" "${RAW_FILE}"

# Only ask podman for a TTY when there is one: `-t` without a terminal (CI,
# piped output) makes podman fail.
TTY_ARGS=()
if [[ -t 0 && -t 1 ]]; then
    TTY_ARGS=(-it)
fi

echo "Installing ${IMAGE} with bootc install to-disk..."
# shellcheck disable=SC2086 # SUDO is intentionally empty or a single word
${SUDO} "${PODMAN}" run \
    --rm \
    "${TTY_ARGS[@]}" \
    --privileged \
    --pid=host \
    --security-opt label=type:unconfined_t \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    -v /dev:/dev \
    -v "${OUTPUT_DIR}":/output \
    "${IMAGE}" \
    bootc install to-disk \
    --skip-fetch-check \
    --generic-image \
    --via-loopback \
    --filesystem btrfs \
    "$@" \
    "/output/$(basename "${RAW_FILE}")"

echo "Converting to qcow2..."
qemu-img convert -f raw -O qcow2 "${RAW_FILE}" "${QCOW2_FILE}"
rm -f "${RAW_FILE}"

if [[ "$(id -u)" -ne 0 ]]; then
    # shellcheck disable=SC2086
    ${SUDO} chown "$(id -u):$(id -g)" "${QCOW2_FILE}"
fi

echo "qcow2 built: ${QCOW2_FILE}"
