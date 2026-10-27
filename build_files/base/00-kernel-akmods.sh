#!/bin/bash
# Hypercube Kernel Modules & NVIDIA Configuration
# Based on Bluefin's approach: https://github.com/ublue-os/bluefin/blob/main/build_files/base/03-install-kernel-akmods.sh
# The NVIDIA driver itself (open kernel modules, userspace, container toolkit)
# comes preinstalled from ghcr.io/ublue-os/base-nvidia; this script adds the
# common hardware kmods and Hypercube's NVIDIA tweaks on top.

set -eoux pipefail

echo "Installing kernel modules and NVIDIA configuration..."

FEDORA_VERSION="$(rpm -E %fedora)"
AKMODS_FLAVOR="${AKMODS_FLAVOR:-main}"

# Get current kernel version from base image (don't replace it)
KERNEL_VERSION=$(rpm -q kernel-core --queryformat "%{VERSION}-%{RELEASE}.%{ARCH}" | tail -n 1)
echo "Using base image kernel: ${KERNEL_VERSION}"

# Fetch akmods container (contains kmods for this kernel)
skopeo copy --retry-times 3 \
  docker://ghcr.io/ublue-os/akmods:"${AKMODS_FLAVOR}"-"${FEDORA_VERSION}" \
  dir:/tmp/akmods

AKMODS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods/"$AKMODS_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods/

# Enable ublue-os akmods COPR
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo

# Install hardware support kmods (xone, openrazer, framework-laptop,
# v4l2loopback) together with their -kmod-common packages from common/.
# Not every kmod exists for every Fedora release (framework-laptop is gone
# from the 45 akmods image), so each one is installed on its own: a missing
# kmod must not take the others down with it.
shopt -s nullglob
for kmod in xone openrazer framework-laptop v4l2loopback; do
  kmod_rpms=(/tmp/akmods/kmods/kmod-"${kmod}"-*.rpm)
  if [[ ${#kmod_rpms[@]} -eq 0 ]]; then
    echo "WARNING: no ${kmod} kmod in akmods:${AKMODS_FLAVOR}-${FEDORA_VERSION}, skipping"
    continue
  fi
  rpms=("${kmod_rpms[@]}" /tmp/akmods/common/"${kmod}"*.rpm)
  echo "Installing ${kmod} kmod..."
  dnf5 -y install "${rpms[@]}" || echo "WARNING: Failed to install ${kmod} kmod"
done
shopt -u nullglob

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
