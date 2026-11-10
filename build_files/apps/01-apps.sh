#!/bin/bash
# Hypercube Applications
# User-facing applications

set -ouex pipefail

echo "Installing applications..."

### Web Browser
dnf5 -y install firefox

### TUI Communication Apps - From Hypercube COPR
dnf5 -y install \
    iamb \
    meli

### Flatpak Applications
# Not installed here: anything written to /var at build time is copied only on
# first install and never updated. The list lives in
# /usr/share/flatpak/preinstall.d/hypercube.preinstall and is installed on the
# machine by hypercube-flatpak-preinstall.service.

echo "Applications installed successfully"
