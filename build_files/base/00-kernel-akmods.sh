#!/bin/bash
# Hypercube Kernel Modules & NVIDIA Configuration
# Based on Bluefin's approach: https://github.com/ublue-os/bluefin/blob/main/build_files/base/03-install-kernel-akmods.sh
# The NVIDIA driver itself (open kernel modules, userspace, container toolkit)
# comes preinstalled from ghcr.io/ublue-os/base-nvidia; this script adds the
# v4l2loopback kmod (from ublue-os/akmods) and Hypercube's NVIDIA tweaks on top.

set -eoux pipefail

echo "Installing kernel modules and NVIDIA configuration..."

FEDORA_VERSION="$(rpm -E %fedora)"
AKMODS_FLAVOR="${AKMODS_FLAVOR:-main}"

# Get current kernel version from base image (don't replace it)
KERNEL_VERSION=$(rpm -q kernel-core --queryformat "%{VERSION}-%{RELEASE}.%{ARCH}" | tail -n 1)
echo "Using base image kernel: ${KERNEL_VERSION}"

# Fetch the akmods image built for exactly this kernel. The floating
# "${AKMODS_FLAVOR}-${FEDORA_VERSION}" tag can point at a different kernel than
# the base image when the two are published at different times; the
# kernel-pinned tag fails fast instead of shipping a module for the wrong kernel.
AKMODS_TAG="${AKMODS_FLAVOR}-${FEDORA_VERSION}-${KERNEL_VERSION}"
echo "Using akmods image: ghcr.io/ublue-os/akmods:${AKMODS_TAG}"
skopeo copy --retry-times 3 \
  docker://ghcr.io/ublue-os/akmods:"${AKMODS_TAG}" \
  dir:/tmp/akmods

AKMODS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods/"$AKMODS_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods/

# Install v4l2loopback (virtual webcam; loaded at boot via
# /usr/lib/modules-load.d/v4l2loopback.conf). The NVIDIA kmods come from
# base-nvidia, so this is the only kmod taken from akmods. Fail the build if it
# is missing or won't install rather than shipping without it.
shopt -s nullglob
kmod_rpms=(/tmp/akmods/kmods/kmod-v4l2loopback-*.rpm /tmp/akmods/common/v4l2loopback-*.rpm)
shopt -u nullglob
if [[ ${#kmod_rpms[@]} -ne 2 ]]; then
  echo "ERROR: expected kmod-v4l2loopback and v4l2loopback RPMs in akmods:${AKMODS_TAG}, found: ${kmod_rpms[*]:-none}"
  exit 1
fi
dnf5 -y install "${kmod_rpms[@]}"

### NVIDIA Configuration ###
# Fail early if the base image ever stops shipping the driver
rpm -q kmod-nvidia nvidia-driver

# Post-install nvidia configuration
rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so

# nvidia-settings ships an XDG autostart entry that runs
# `nvidia-settings --load-config-only`. That needs an X server driven by the
# NVIDIA driver, so under Hyprland (Wayland) it always fails. uwsm turns XDG
# autostart entries into systemd user units, which then show up as failed
# (app-nvidia\x2dsettings\x2dload@autostart.service). Drop the entry.
rm -f /etc/xdg/autostart/nvidia-settings-load.desktop

# Configure kernel arguments for NVIDIA (base-nvidia doesn't set any)
mkdir -p /usr/lib/bootc/kargs.d/
cat >/usr/lib/bootc/kargs.d/00-nvidia.toml <<'EOF'
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF

# Cleanup
rm -rf /tmp/akmods /tmp/rpms

echo "Kernel modules and NVIDIA configuration installed for kernel ${KERNEL_VERSION}"
