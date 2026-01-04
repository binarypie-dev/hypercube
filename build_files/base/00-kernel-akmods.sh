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
    /tmp/akmods/kmods/*framework-laptop*.rpm \
    || true

# Install v4l2loopback userspace tools from RPM Fusion (without akmod dependency)
# Then install pre-built kmod from ublue akmods
dnf5 -y install \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm"

# Install userspace package but exclude akmod (we use pre-built kmod instead)
dnf5 -y install --exclude=akmod-v4l2loopback --exclude=akmods v4l2loopback || echo "WARNING: Failed to install v4l2loopback userspace"
dnf5 -y remove rpmfusion-free-release rpmfusion-nonfree-release || true

# Install pre-built v4l2loopback kmod from ublue akmods
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

# Fetch and run Universal Blue's nvidia-install script
curl -sSL "https://raw.githubusercontent.com/ublue-os/main/main/build_files/nvidia-install.sh" -o /tmp/nvidia-install.sh
chmod +x /tmp/nvidia-install.sh
IMAGE_NAME="base-main" RPMFUSION_MIRROR="" /tmp/nvidia-install.sh

# Post-install nvidia configuration
rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so

# Configure kernel arguments for NVIDIA
mkdir -p /usr/lib/bootc/kargs.d/
cat > /usr/lib/bootc/kargs.d/00-nvidia.toml << 'EOF'
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF

# Cleanup
rm -rf /tmp/akmods /tmp/akmods-nvidia /tmp/akmods-rpms /tmp/rpms /tmp/nvidia-install.sh

echo "NVIDIA drivers installed successfully for kernel ${KERNEL_VERSION}"
