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

### Flatpak Applications (system-wide, baked into image)
flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --system --noninteractive flathub \
    io.github.kolunmi.Bazaar \
    com.usebottles.bottles \
    io.github.dvlv.boxbuddyrs \
    org.gnome.Boxes \
    com.github.tchx84.Flatseal \
    be.alexandervanhee.gradia \
    io.github.seadve.Kooha \
    io.podman_desktop.PodmanDesktop \
    org.mozilla.Thunderbird \
    io.github.flattool.Warehouse

echo "Applications installed successfully"
