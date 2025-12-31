#!/bin/bash
# Hypercube Applications
# User-facing applications

set -ouex pipefail

echo "Installing applications..."

### Web Browser
dnf5 -y install firefox

echo "Applications installed successfully"
