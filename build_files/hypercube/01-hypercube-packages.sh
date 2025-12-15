#!/bin/bash
# Hypercube Package Installation
# Installs Hyprland compositor stack, CLI tools, terminals, and editors

set -ouex pipefail

echo "Installing Hypercube packages..."

# Clean DNF cache first
dnf5 -y clean all

### Compositor / Hyprland Stack
dnf5 -y copr enable sdegler/hyprland
dnf5 -y install \
    hyprland \
    hyprland-contrib \
    hyprland-plugins \
    hyprland-qtutils \
    hyprpaper \
    hyprpicker \
    hypridle \
    hyprshot \
    hyprlock \
    hyprpolkitagent \
    pyprland \
    waybar-git \
    xdg-desktop-portal-hyprland

### CLI Tools (skip packages already in bluefin-dx)
dnf5 -y install \
    fd-find \
    qt6ct

### Lazygit from COPR
dnf5 -y copr enable atim/lazygit
dnf5 -y install lazygit

### Quickshell - Application Launcher, Notifications, OSD
dnf5 -y copr enable errornointernet/quickshell
dnf5 -y install quickshell

### Terminals
dnf5 -y copr enable wezfurlong/wezterm-nightly
dnf5 -y install wezterm

dnf5 -y copr enable scottames/ghostty
dnf5 -y install ghostty

### Editor
dnf5 -y copr enable agriffis/neovim-nightly
dnf5 -y install neovim python3-neovim

echo "Hypercube packages installed successfully"
