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
dnf5 -y copr enable solopasha/hyprland
dnf5 -y install waybar-git xdg-desktop-portal-hyprland hyprland hyprland-contrib hyprland-plugins hyprpaper hyprpicker hypridle hyprshot hyprlock pyprland xdg-desktop-portal-hyprland hyprland-qtutils

# CLI Tools
dnf5 -y install fd-find brightnessctl playerctl

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

# Configure XDG environment for Hypercube
# This makes all configs in /usr/share/hypercube/config discoverable
# while preserving user and admin override capabilities
install -Dm644 /ctx/60-hypercube-xdg.conf /usr/lib/environment.d/60-hypercube-xdg.conf

# systemctl enable podman.socket

### Install Hypercube branding assets
# Install logo files to standard locations if they exist
if [ -d /ctx/branding ]; then
  # Install to pixmaps for system-wide use
  mkdir -p /usr/share/pixmaps
  cp -f /ctx/branding/hypercube-logo.png /usr/share/pixmaps/ 2>/dev/null || true
  cp -f /ctx/branding/hypercube-logo.svg /usr/share/pixmaps/ 2>/dev/null || true

  # Install icons to hicolor theme
  for size in 48 64 128 256; do
    if [ -f "/ctx/branding/hypercube-icon-${size}.png" ]; then
      mkdir -p "/usr/share/icons/hicolor/${size}x${size}/apps"
      cp -f "/ctx/branding/hypercube-icon-${size}.png" "/usr/share/icons/hicolor/${size}x${size}/apps/hypercube.png"
    fi
  done

  # Install SVG icon if available
  if [ -f "/ctx/branding/hypercube-logo.svg" ]; then
    mkdir -p /usr/share/icons/hicolor/scalable/apps
    cp -f /ctx/branding/hypercube-logo.svg /usr/share/icons/hicolor/scalable/apps/hypercube.svg
  fi
fi

### Install Hypercube Plymouth theme
if [ -d /ctx/branding/plymouth/hypercube ]; then
  echo "Installing Hypercube Plymouth theme..."

  # Install plymouth-plugin-script (required for script-based themes)
  dnf5 -y clean all
  dnf5 -y install plymouth-plugin-script

  # Create theme directory
  mkdir -p /usr/share/plymouth/themes/hypercube

  # Copy all theme files
  cp -r /ctx/branding/plymouth/hypercube/* /usr/share/plymouth/themes/hypercube/

  # Set correct permissions
  chmod 644 /usr/share/plymouth/themes/hypercube/*
  chmod 755 /usr/share/plymouth/themes/hypercube

  # Set Hypercube as the default Plymouth theme
  plymouth-set-default-theme hypercube

  # Configure Plymouth daemon
  mkdir -p /etc/plymouth
  cat >/etc/plymouth/plymouthd.conf <<EOF
[Daemon]
Theme=hypercube
ShowDelay=0
DeviceTimeout=8
EOF

  # Install dracut configuration to ensure Plymouth is included in initramfs
  mkdir -p /etc/dracut.conf.d
  cp /ctx/50-hypercube-plymouth.conf /etc/dracut.conf.d/

  # Configure bootc kernel arguments for Plymouth
  # These ensure Plymouth shows during early boot and hides firmware logo
  mkdir -p /usr/lib/bootc/kargs.d
  cp /ctx/hypercube-kargs.json /usr/lib/bootc/kargs.d/

  # Rebuild initramfs to include Plymouth theme
  # This is required for the theme to be available during early boot
  # Note: xattr warnings during build are harmless (container fs limitation)
  echo "Rebuilding initramfs with Plymouth theme..."
  dracut --force --regenerate-all

  echo "Hypercube Plymouth theme installed successfully"
fi

### Install Quickshell config
# Install quickshell launcher configuration to system-wide location
if [ -d /usr/share/hypercube/config/quickshell ]; then
  echo "Installing Quickshell launcher configuration..."
  mkdir -p /etc/skel/.config/quickshell
  cp -r /usr/share/hypercube/config/quickshell/* /etc/skel/.config/quickshell/
  echo "Quickshell configuration installed successfully"
fi

### Install GDM branding (login screen customization)
if [ -d /usr/share/hypercube/config/gdm/dconf ]; then
  echo "Installing GDM branding..."

  # Install dconf profile for GDM
  mkdir -p /etc/dconf/profile
  cp -f /usr/share/hypercube/config/gdm/dconf/profile /etc/dconf/profile/gdm

  # Create dconf database directory
  mkdir -p /etc/dconf/db/hypercube-gdm.d

  # Copy the GDM settings file
  cp -f /usr/share/hypercube/config/gdm/dconf/hypercube-gdm /etc/dconf/db/hypercube-gdm.d/00-hypercube

  # Compile the dconf database
  dconf update

  echo "GDM branding installed successfully"
fi

### Install GDM Tokyo Night theme CSS
if [ -f /usr/share/hypercube/config/gdm/gnome-shell/gnome-shell.css ]; then
  echo "Installing GDM Tokyo Night CSS theme..."

  # Install custom CSS to GDM's gnome-shell theme directory
  mkdir -p /usr/share/gnome-shell/theme
  cp -f /usr/share/hypercube/config/gdm/gnome-shell/gnome-shell.css /usr/share/gnome-shell/theme/gdm.css

  echo "GDM Tokyo Night CSS theme installed successfully"
fi
