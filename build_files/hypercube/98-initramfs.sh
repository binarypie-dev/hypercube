#!/bin/bash
# Regenerate initramfs after all kernel modules are installed
# This is critical for bootc containers that change the kernel

set -ouex pipefail

echo "Regenerating initramfs..."

QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-(\d+\.\d+\.\d+)' | sed -E 's/kernel-//')"
echo "Kernel version: ${QUALIFIED_KERNEL}"

export DRACUT_NO_XATTR=1
/usr/bin/dracut \
    --no-hostonly \
    --kver "${QUALIFIED_KERNEL}" \
    --reproducible \
    --add ostree \
    -f "/lib/modules/${QUALIFIED_KERNEL}/initramfs.img"

chmod 0600 "/lib/modules/${QUALIFIED_KERNEL}/initramfs.img"

echo "Initramfs regenerated successfully"
