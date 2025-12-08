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

### Install Hypercube Plymouth branding
# Uses Fedora's built-in spinner theme with a custom watermark overlay
# No plugin required - just drop watermark.png into the spinner theme directory
if [ -f /ctx/branding/plymouth/hypercube/watermark.png ]; then
  echo "Installing Hypercube Plymouth watermark..."

  # Install watermark to spinner theme directory
  # The spinner theme automatically displays watermark.png if present
  cp /ctx/branding/plymouth/hypercube/watermark.png /usr/share/plymouth/themes/spinner/

  # Configure bootc kernel arguments for Plymouth
  mkdir -p /usr/lib/bootc/kargs.d
  cp /ctx/hypercube-kargs.json /usr/lib/bootc/kargs.d/

  echo "Hypercube Plymouth branding installed successfully"
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
  echo "Installing GDM dconf settings..."

  # Install dconf profile for GDM
  mkdir -p /etc/dconf/profile
  cp -f /usr/share/hypercube/config/gdm/dconf/profile /etc/dconf/profile/gdm

  # Create dconf database directory
  mkdir -p /etc/dconf/db/hypercube-gdm.d

  # Copy the GDM settings file
  cp -f /usr/share/hypercube/config/gdm/dconf/hypercube-gdm /etc/dconf/db/hypercube-gdm.d/00-hypercube

  # Compile the dconf database
  dconf update

  echo "GDM dconf settings installed successfully"
fi

### Install GDM theme (modifies gnome-shell-theme.gresource)
# This patches the GDM background to show our logo centered on black
if [ -f /ctx/gdm-theme.sh ] && [ -f /usr/share/pixmaps/hypercube-logo.png ]; then
  # Install tools needed to extract and recompile gresource
  dnf5 -y install glib2-devel

  /ctx/gdm-theme.sh

  # Remove build tools to keep image clean
  dnf5 -y remove glib2-devel
  dnf5 -y autoremove
fi
