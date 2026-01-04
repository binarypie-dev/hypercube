#!/bin/bash
# Hypercube Base System
# Installs core system components, display manager (greetd + regreet), and hardware support

set -ouex pipefail

echo "Installing Hypercube base system..."

# Clean DNF cache first
dnf5 -y clean all

### Enable Hypercube COPR for custom packages
dnf5 -y copr enable binarypie/hypercube

### Display Manager: greetd + regreet
# regreet from binarypie/hypercube COPR
# cage is a minimal Wayland compositor to host regreet and the first-boot wizard
dnf5 -y install \
    greetd \
    greetd-selinux \
    cage \
    regreet

### Desktop Portals & Integration
dnf5 -y install \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-user-dirs \
    xdg-utils

### Credential & Secret Storage
dnf5 -y install \
    gnome-keyring \
    seahorse

### Audio (Pipewire should be in base, but ensure full stack)
dnf5 -y install \
    pipewire \
    pipewire-pulseaudio \
    pipewire-alsa \
    wireplumber

### Networking
dnf5 -y install \
    NetworkManager \
    NetworkManager-wifi \
    NetworkManager-bluetooth

### Bluetooth
dnf5 -y install \
    bluez \
    bluez-tools

### Power Management
dnf5 -y install \
    power-profiles-daemon \
    upower

### Fonts (base set - more can be added)
dnf5 -y install \
    google-noto-fonts-common \
    google-noto-sans-fonts \
    google-noto-serif-fonts \
    google-noto-sans-mono-fonts \
    google-noto-emoji-fonts \
    fontawesome-fonts-all \
    jetbrains-mono-fonts-all

### Utilities
dnf5 -y install \
    wl-clipboard \
    xdg-utils \
    polkit \
    dbus-daemon \
    gnome-disk-utility

### File Management
dnf5 -y install \
    nautilus \
    file-roller \
    gvfs \
    gvfs-mtp \
    gvfs-gphoto2 \
    gvfs-smb

### Flatpak (ensure latest version for preinstall.d support)
dnf5 -y install flatpak

### Homebrew integration (from ublue COPR)
dnf5 -y copr enable ublue-os/packages
dnf5 -y install ublue-brew

### Create greeter user for greetd
# greetd runs the greeter as this user
if ! id -u greeter &>/dev/null; then
    useradd -r -M -s /usr/bin/nologin greeter
fi

### Enable services
systemctl enable greetd.service
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable power-profiles-daemon.service
systemctl enable flatpak-add-flathub.service

### Disable services we don't need
systemctl disable gdm.service 2>/dev/null || true
systemctl disable sddm.service 2>/dev/null || true

echo "Hypercube base system installed successfully"
