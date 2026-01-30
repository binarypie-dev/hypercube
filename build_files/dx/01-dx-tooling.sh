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
dnf5 -y install \
    ShellCheck \
    shfmt

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
