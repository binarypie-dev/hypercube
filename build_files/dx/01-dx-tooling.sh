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
    tar

echo "DX tooling installed successfully"
