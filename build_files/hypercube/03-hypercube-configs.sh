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

### Wezterm configs
# Wezterm doesn't support XDG_CONFIG_DIRS for system defaults
install -Dm644 "${CONFIG_DIR}/wezterm/wezterm.lua" /etc/skel/.config/wezterm/wezterm.lua

### GTK theme settings - install to /etc/skel for new users
install -Dm644 "${CONFIG_DIR}/gtk-3.0/settings.ini" /etc/skel/.config/gtk-3.0/settings.ini
install -Dm644 "${CONFIG_DIR}/gtk-4.0/settings.ini" /etc/skel/.config/gtk-4.0/settings.ini

### Git UI tools configs (Tokyo Night themed)
install -Dm644 "${CONFIG_DIR}/gitui/theme.ron" /etc/skel/.config/gitui/theme.ron
install -Dm644 "${CONFIG_DIR}/gitui/key_bindings.ron" /etc/skel/.config/gitui/key_bindings.ron
install -Dm644 "${CONFIG_DIR}/lazygit/config.yml" /etc/skel/.config/lazygit/config.yml

### Qt6 theming (Tokyo Night color scheme)
install -Dm644 "${CONFIG_DIR}/qt6ct/qt6ct.conf" /etc/skel/.config/qt6ct/qt6ct.conf
install -Dm644 "${CONFIG_DIR}/qt6ct/colors/TokyoNight.conf" /usr/share/qt6ct/colors/TokyoNight.conf

### Quickshell launcher configuration
if [ -d "${CONFIG_DIR}/quickshell" ]; then
    echo "Installing Quickshell launcher configuration..."
    mkdir -p /etc/skel/.config/quickshell
    cp -r "${CONFIG_DIR}/quickshell/"* /etc/skel/.config/quickshell/
    echo "Quickshell configuration installed successfully"
fi

echo "Hypercube configurations installed successfully"
