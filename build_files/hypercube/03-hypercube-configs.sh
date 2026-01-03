#!/bin/bash
# Hypercube Configuration Installation
# Installs config files to system locations and /etc/skel for new users

set -ouex pipefail

echo "Installing Hypercube configurations..."

CONFIG_DIR="/usr/share/hypercube/config"

### Install nvimd (containerized neovim wrapper)
install -Dm755 "${CONFIG_DIR}/nvim/bin/nvimd" /usr/bin/nvimd

### Fish shell configs
# Fish doesn't use XDG_CONFIG_DIRS, so we install to /etc/fish
install -Dm644 "${CONFIG_DIR}/fish/config.fish" /etc/fish/config.fish
cp -r "${CONFIG_DIR}/fish/conf.d" /etc/fish/
cp -r "${CONFIG_DIR}/fish/functions" /etc/fish/ 2>/dev/null || true
cp -r "${CONFIG_DIR}/fish/completions" /etc/fish/ 2>/dev/null || true

### Set fish as the default shell for all users
# Add fish to /etc/shells if not present
grep -qxF '/usr/bin/fish' /etc/shells || echo '/usr/bin/fish' >> /etc/shells
# Set fish as default shell in /etc/skel for new users (via useradd defaults)
sed -i 's|^SHELL=.*|SHELL=/usr/bin/fish|' /etc/default/useradd 2>/dev/null || \
    echo 'SHELL=/usr/bin/fish' >> /etc/default/useradd

### Starship prompt configuration
# Starship config is read from STARSHIP_CONFIG env var set in fish config
# Config lives at /usr/share/hypercube/config/starship/starship.toml (read-only)

### Ghostty terminal - stub that sources system config
# Users can customize by adding settings after the config-file line
mkdir -p /etc/skel/.config/ghostty
cat > /etc/skel/.config/ghostty/config << 'EOF'
# Hypercube Ghostty Configuration
# System defaults are sourced below. Add your customizations after this line.
# To replace defaults entirely, remove or comment out the config-file line.

config-file = /usr/share/hypercube/config/ghostty/config

# Your customizations below:
EOF

### Hyprland - stub that sources system config
# Users can customize by adding settings after the source line
# Hyprland parses linearly: system config first, then user customizations
mkdir -p /etc/skel/.config/hypr
cat > /etc/skel/.config/hypr/hyprland.conf << 'EOF'
# Hypercube Hyprland Configuration
# System defaults are sourced below. Add your customizations after this line.
# Settings defined after source will override the defaults.
# To replace defaults entirely, remove or comment out the source line.

source = /usr/share/hypercube/config/hypr/hyprland.conf

# Your customizations below:

EOF

### GTK theme settings - install to /etc/xdg/ for system-wide defaults
# Users can override by creating ~/.config/gtk-3.0/settings.ini
install -Dm644 "${CONFIG_DIR}/gtk-3.0/settings.ini" /etc/xdg/gtk-3.0/settings.ini
install -Dm644 "${CONFIG_DIR}/gtk-4.0/settings.ini" /etc/xdg/gtk-4.0/settings.ini

### Git UI tools (gitui, lazygit), Quickshell
# These support XDG_CONFIG_DIRS and will find configs in /usr/share/hypercube/config/
# No skel copy needed - users can override by creating ~/.config/<app>/

### Qt6 theming (Tokyo Night color scheme)
# Qt6ct supports XDG_CONFIG_DIRS for system-wide defaults
install -Dm644 "${CONFIG_DIR}/qt6ct/qt6ct.conf" /etc/xdg/qt6ct/qt6ct.conf
install -Dm644 "${CONFIG_DIR}/qt6ct/colors/TokyoNight.conf" /usr/share/qt6ct/colors/TokyoNight.conf

### ReGreet login greeter configuration (Tokyo Night themed)
install -Dm644 "${CONFIG_DIR}/regreet/regreet.toml" /etc/greetd/regreet.toml
install -Dm644 "${CONFIG_DIR}/regreet/regreet.css" /etc/greetd/regreet.css

### Enable xdg-desktop-portal-gtk for dark mode detection (Firefox, etc.)
# This portal provides the org.freedesktop.appearance.color-scheme setting
systemctl --global enable xdg-desktop-portal-gtk.service

echo "Hypercube configurations installed successfully"
