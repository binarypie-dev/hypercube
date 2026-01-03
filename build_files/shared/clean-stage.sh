#!/bin/bash
# Hypercube Cleanup Script
# Disables COPR repos and cleans up after build

set -ouex pipefail

echo "Disabling COPR repositories..."

# Disable all COPR repos that were enabled during build
# This ensures the final image doesn't have external repos enabled

# Hypercube COPR (our self-maintained packages)
dnf5 -y copr disable binarypie/hypercube || true

echo "Cleaning package caches..."
dnf5 -y clean all

# Remove any leftover build artifacts
rm -rf /tmp/* 2>/dev/null || true

echo "Cleanup complete"
