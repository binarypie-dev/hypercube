#!/bin/bash

set -ouex pipefail

# Install build dependencies for Walker (Rust-based with GTK4)
dnf5 -y install git rust cargo gtk4-devel gtk4-layer-shell-devel protobuf-compiler cairo-devel poppler-glib-devel

# Clone Walker repository
WALKER_VERSION="v2.12.0"
git clone --depth 1 --branch ${WALKER_VERSION} https://github.com/abenz1267/walker.git /tmp/walker

cd /tmp/walker

# Set Cargo environment variables for build
export CARGO_HOME=/tmp/cargo
export CARGO_TARGET_DIR=/tmp/cargo-target

# Build Walker with release optimizations
cargo build --release

# Install binary
install -Dm755 /tmp/cargo-target/release/walker /usr/bin/walker

# Install desktop file if it exists
if [ -f resources/walker.desktop ]; then
    install -Dm644 resources/walker.desktop /usr/share/applications/walker.desktop
fi

# Install default resources
mkdir -p /usr/share/walker
if [ -d resources ]; then
    cp -r resources/* /usr/share/walker/ || true
fi

# Clean up
cd /
rm -rf /tmp/walker /tmp/cargo /tmp/cargo-target

# Ensure runtime dependencies are installed (gtk4-layer-shell is needed at runtime)
dnf5 -y install gtk4-layer-shell

# Remove build-only dependencies to keep layer small
dnf5 -y remove rust cargo protobuf-compiler gtk4-devel gtk4-layer-shell-devel cairo-devel poppler-glib-devel
dnf5 -y clean all

