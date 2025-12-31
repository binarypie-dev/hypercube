#!/bin/bash
# Hypercube Kernel & NVIDIA Driver Installation
# Based on Bluefin's approach: https://github.com/ublue-os/bluefin/blob/main/build_files/base/03-install-kernel-akmods.sh
# Simplified for Hypercube: no ZFS, no beta channel, always includes NVIDIA

set -eoux pipefail

echo "Installing kernel, akmods, and NVIDIA drivers..."

FEDORA_VERSION="$(rpm -E %fedora)"
AKMODS_FLAVOR="${AKMODS_FLAVOR:-coreos-stable}"

# Remove existing kernel packages
for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra; do
    rpm --erase "$pkg" --nodeps || true
done

# Fetch akmods container (contains kernel RPMs and kmods)
skopeo copy --retry-times 3 \
    docker://ghcr.io/ublue-os/akmods:"${AKMODS_FLAVOR}"-"${FEDORA_VERSION}" \
    dir:/tmp/akmods

AKMODS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods/"$AKMODS_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods/

# Install kernel from akmods cache
# Use rpm directly to skip scriptlets that try to run dracut (fails in container builds)
rpm -ivh --nodeps --noscripts \
    /tmp/kernel-rpms/kernel-[0-9]*.rpm \
    /tmp/kernel-rpms/kernel-core-*.rpm \
    /tmp/kernel-rpms/kernel-modules-*.rpm \
    /tmp/kernel-rpms/kernel-modules-core-*.rpm \
    /tmp/kernel-rpms/kernel-modules-extra-*.rpm

rpm -ivh --nodeps --noscripts /tmp/kernel-rpms/kernel-devel-*.rpm

# Lock kernel version to prevent mismatches
dnf5 versionlock add kernel kernel-devel kernel-devel-matched kernel-core kernel-modules kernel-modules-core kernel-modules-extra

# Get installed kernel version for nvidia akmods
KERNEL_VERSION=$(rpm -q kernel-core --queryformat "%{VERSION}-%{RELEASE}.%{ARCH}" | tail -n 1)
echo "Installed kernel: ${KERNEL_VERSION}"

# Enable ublue-os akmods COPR
sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo

# Install hardware support akmods
dnf5 -y install \
    /tmp/akmods/kmods/*xone*.rpm \
    /tmp/akmods/kmods/*openrazer*.rpm \
    /tmp/akmods/kmods/*framework-laptop*.rpm \
    || true

# Install RPM Fusion for v4l2loopback
dnf5 -y install \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm"

dnf5 -y install v4l2loopback /tmp/akmods/kmods/*v4l2loopback*.rpm || true
dnf5 -y remove rpmfusion-free-release rpmfusion-nonfree-release || true

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
rm -rf /tmp/akmods /tmp/akmods-nvidia /tmp/akmods-rpms /tmp/kernel-rpms /tmp/rpms /tmp/nvidia-install.sh

echo "Kernel and NVIDIA drivers installed successfully"
