#!/bin/bash
# Hypercube Cleanup Script
# Disables COPR repos and cleans up after build

set -ouex pipefail

echo "Disabling COPR repositories..."

# Disable all COPR repos that were enabled during build
# This ensures the final image doesn't have external repos enabled
dnf5 -y copr disable sdegler/hyprland || true
dnf5 -y copr disable errornointernet/quickshell || true
dnf5 -y copr disable wezfurlong/wezterm-nightly || true
dnf5 -y copr disable scottames/ghostty || true
dnf5 -y copr disable agriffis/neovim-nightly || true
dnf5 -y copr disable atim/lazygit || true

echo "Cleaning package caches..."
dnf5 -y clean all

# Remove any leftover build artifacts
rm -rf /tmp/* 2>/dev/null || true

echo "Cleanup complete"
