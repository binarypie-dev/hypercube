#!/bin/bash
# Hypercube Kernel & NVIDIA Driver Installation
# Based on Bluefin's approach: https://github.com/ublue-os/bluefin/blob/main/build_files/base/03-install-kernel-akmods.sh
# Simplified for Hypercube: no ZFS, no beta channel, always includes NVIDIA

set -eoux pipefail

echo "Installing kernel, akmods, and NVIDIA drivers..."

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

# Install hardware support akmods
dnf5 -y install \
  /tmp/akmods/kmods/*xone*.rpm \
  /tmp/akmods/kmods/*openrazer*.rpm \
  /tmp/akmods/kmods/*framework-laptop*.rpm ||
  true

# Install pre-built v4l2loopback kmod from ublue akmods (userspace tools not needed)
echo "Installing v4l2loopback kmod..."
ls -la /tmp/akmods/kmods/*v4l2loopback*.rpm || echo "WARNING: v4l2loopback kmod not found"
dnf5 -y install /tmp/akmods/kmods/*v4l2loopback*.rpm || echo "WARNING: Failed to install v4l2loopback kmod"

### NVIDIA Installation ###
echo "Installing NVIDIA drivers..."

# Fetch NVIDIA akmods
skopeo copy --retry-times 3 \
  docker://ghcr.io/ublue-os/akmods-nvidia-open:"${AKMODS_FLAVOR}"-"${FEDORA_VERSION}"-"${KERNEL_VERSION}" \
  dir:/tmp/akmods-nvidia

NVIDIA_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods-nvidia/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods-nvidia/"$NVIDIA_TARGZ" -C /tmp/

# nvidia-install.sh expects RPMs at /tmp/akmods-rpms/
mkdir -p /tmp/akmods-rpms
mv /tmp/rpms/* /tmp/akmods-rpms/

# Exclude golang nvidia toolkit from Fedora repo
dnf5 config-manager setopt excludepkgs=golang-github-nvidia-container-toolkit || true

# Update mesa packages first to avoid RPM Fusion version conflicts
dnf5 -y update mesa* || true

# Run Universal Blue's nvidia-install script. Upstream removed the standalone
# build_files/nvidia-install.sh from ublue-os/main (PR #2723) and now ships it
# bundled inside the akmods-nvidia container, extracted above to
# /tmp/akmods-rpms/ublue-os/. AKMODNV_PATH points the script at its RPMs.
# (The old libnvidia-ml.i686 workaround is no longer needed: the bundled
# script was fixed upstream to stop requesting that retired package.)
AKMODNV_PATH=/tmp/akmods-rpms IMAGE_NAME="base-main" \
  bash /tmp/akmods-rpms/ublue-os/nvidia-install.sh

# Post-install nvidia configuration
rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so

# Configure kernel arguments for NVIDIA
mkdir -p /usr/lib/bootc/kargs.d/
cat >/usr/lib/bootc/kargs.d/00-nvidia.toml <<'EOF'
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF

# Cleanup
rm -rf /tmp/akmods /tmp/akmods-nvidia /tmp/akmods-rpms /tmp/rpms

echo "NVIDIA drivers installed successfully for kernel ${KERNEL_VERSION}"
