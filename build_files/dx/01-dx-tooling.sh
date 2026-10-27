#!/bin/bash
# Hypercube DX (Developer Experience) Tooling
# Installs Distrobox, container tools, and dev utilities

set -ouex pipefail

echo "Installing DX tooling..."

### Distrobox - Container-based dev environments
dnf5 -y install distrobox

### Container tools (Podman is in base-main, add full stack)
dnf5 -y install \
    podman \
    podman-compose \
    podman-docker \
    podman-tui \
    buildah \
    skopeo

### Additional dev utilities
dnf5 -y install \
    just \
    direnv \
    openssl \
    openssh-clients \
    rsync \
    wget \
    curl \
    unzip \
    zip \
    tar \
    qemu-img

### VM management tools
dnf5 -y install \
    libvirt \
    virt-install \
    virt-manager \
    virt-viewer

### Linting and formatting
dnf5 -y install ShellCheck

# shfmt isn't packaged in Fedora 45, so install the upstream static binary.
# Upstream publishes no checksum file; the hash below was taken from the
# v3.14.1 release asset when it was pinned.
SHFMT_VERSION="v3.14.1"
SHFMT_SHA256="76e77641faa025814b77f153b29796b8e6fa2fca03e0c76a691608b86c7ea7bf"
curl -fsSL --retry 3 -o /tmp/shfmt \
    "https://github.com/mvdan/sh/releases/download/${SHFMT_VERSION}/shfmt_${SHFMT_VERSION}_linux_amd64"
echo "${SHFMT_SHA256}  /tmp/shfmt" | sha256sum -c -
install -m 0755 /tmp/shfmt /usr/bin/shfmt
rm -f /tmp/shfmt

### Container signing
dnf5 -y install cosign

### TUI Developer Tools - From Hypercube COPR
dnf5 -y install \
    lazyjournal \
    lazysql \
    resterm

### Enable libvirtd for VM management
systemctl enable libvirtd.service

echo "DX tooling installed successfully"
