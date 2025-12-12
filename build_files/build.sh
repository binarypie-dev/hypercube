#!/bin/bash

set -ouex pipefail

### Apply Hypercube Branding
# This must run early to set up os-release and image-info
/ctx/00-hypercube-branding.sh

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# Compositor / Hyprland Utilities
dnf5 -y clean all
dnf5 -y copr enable sdegler/hyprland
dnf5 -y install waybar-git xdg-desktop-portal-hyprland hyprland hyprland-contrib hyprland-plugins hyprpaper hyprpicker hypridle hyprshot hyprlock pyprland xdg-desktop-portal-hyprland hyprland-qtutils

# CLI Tools
dnf5 -y install fd-find brightnessctl playerctl

# Tokyo Night GTK Theme and Qt/Kvantum theming
dnf5 -y install gtk-murrine-engine sassc git kvantum qt6ct adwaita-cursor-theme
# Clone and install Tokyo Night GTK theme
git clone --depth 1 https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme.git /tmp/tokyonight-gtk
/tmp/tokyonight-gtk/themes/install.sh -d /usr/share/themes -n Tokyonight --tweaks black
# Install icon theme
mkdir -p /usr/share/icons
cp -r /tmp/tokyonight-gtk/icons/Tokyonight-Dark /usr/share/icons/
cp -r /tmp/tokyonight-gtk/icons/Tokyonight-Light /usr/share/icons/
gtk-update-icon-cache /usr/share/icons/Tokyonight-Dark 2>/dev/null || true
gtk-update-icon-cache /usr/share/icons/Tokyonight-Light 2>/dev/null || true
rm -rf /tmp/tokyonight-gtk

# Install Kvantum Tokyo Night theme system-wide
mkdir -p /usr/share/Kvantum
cp -r /usr/share/hypercube/config/Kvantum/tokyo-night /usr/share/Kvantum/

# Remove extra things
# TODO: Figure out what we don't need from solopasha/hyprland

# Quickshell - Application Launcher, Notifications, OSD
dnf5 -y copr enable errornointernet/quickshell
dnf5 -y install quickshell

# Terminals
dnf5 -y copr enable wezfurlong/wezterm-nightly
dnf5 -y install wezterm

dnf -y copr enable scottames/ghostty
dnf -y install ghostty

# Editor
dnf5 -y copr enable agriffis/neovim-nightly
dnf5 -y install neovim python3-neovim

# Install nvimd (containerized neovim wrapper)
install -Dm755 /usr/share/hypercube/config/nvim/bin/nvimd /usr/bin/nvimd

# Fish shell configs
# Fish doesn't use XDG_CONFIG_DIRS, so we install to /etc/fish
install -Dm644 /usr/share/hypercube/config/fish/config.fish /etc/fish/config.fish
cp -r /usr/share/hypercube/config/fish/conf.d /etc/fish/
cp -r /usr/share/hypercube/config/fish/functions /etc/fish/ 2>/dev/null || true
cp -r /usr/share/hypercube/config/fish/completions /etc/fish/ 2>/dev/null || true

# Wezterm configs
# Wezterm doesn't support XDG_CONFIG_DIRS for system defaults, so we install to /etc/skel
# which will be copied to new user home directories
install -Dm644 /usr/share/hypercube/config/wezterm/wezterm.lua /etc/skel/.config/wezterm/wezterm.lua

# GTK theme settings - install to /etc/skel for new users
install -Dm644 /usr/share/hypercube/config/gtk-3.0/settings.ini /etc/skel/.config/gtk-3.0/settings.ini
install -Dm644 /usr/share/hypercube/config/gtk-4.0/settings.ini /etc/skel/.config/gtk-4.0/settings.ini

# Qt/Kvantum theme settings - install to /etc/skel for new users
install -Dm644 /usr/share/hypercube/config/qt6ct/qt6ct.conf /etc/skel/.config/qt6ct/qt6ct.conf
install -Dm644 /usr/share/hypercube/config/Kvantum/kvantum.kvconfig /etc/skel/.config/Kvantum/kvantum.kvconfig

# Configure XDG environment for Hypercube
# This makes all configs in /usr/share/hypercube/config discoverable
# while preserving user and admin override capabilities
install -Dm644 /ctx/60-hypercube-xdg.conf /usr/lib/environment.d/60-hypercube-xdg.conf

# systemctl enable podman.socket


### Install Quickshell config
# Install quickshell launcher configuration to system-wide location
if [ -d /usr/share/hypercube/config/quickshell ]; then
  echo "Installing Quickshell launcher configuration..."
  mkdir -p /etc/skel/.config/quickshell
  cp -r /usr/share/hypercube/config/quickshell/* /etc/skel/.config/quickshell/
  echo "Quickshell configuration installed successfully"
fi
