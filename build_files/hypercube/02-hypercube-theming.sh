#!/bin/bash
# Hypercube Theming
# Installs Tokyo Night GTK theme and icon themes

set -ouex pipefail

echo "Installing Tokyo Night theme..."

### Build dependencies for Tokyo Night GTK theme
dnf5 -y install gtk-murrine-engine sassc git adwaita-cursor-theme

### Clone and install Tokyo Night GTK theme
git clone --depth 1 https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme.git /tmp/tokyonight-gtk
/tmp/tokyonight-gtk/themes/install.sh -d /usr/share/themes -n Tokyonight --tweaks black

### Install icon themes
mkdir -p /usr/share/icons
cp -r /tmp/tokyonight-gtk/icons/Tokyonight-Dark /usr/share/icons/
cp -r /tmp/tokyonight-gtk/icons/Tokyonight-Light /usr/share/icons/

### Update icon caches (ignore errors if themes don't have index.theme)
gtk-update-icon-cache /usr/share/icons/Tokyonight-Dark 2>/dev/null || true
gtk-update-icon-cache /usr/share/icons/Tokyonight-Light 2>/dev/null || true

### Cleanup
rm -rf /tmp/tokyonight-gtk

### Create symlinks in /etc/skel for flatpak theme access
# Flatpaks access ~/.themes and ~/.icons, symlinks allow system theme updates to propagate
mkdir -p /etc/skel/.themes /etc/skel/.icons
ln -sf /usr/share/themes/Tokyonight-Dark /etc/skel/.themes/
ln -sf /usr/share/icons/Tokyonight-Dark /etc/skel/.icons/

echo "Tokyo Night theme installed successfully"
