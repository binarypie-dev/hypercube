#!/bin/bash
# Hypercube Configuration Installation
# Installs config files to system locations and /etc/skel for new users

set -ouex pipefail

echo "Installing Hypercube configurations..."

CONFIG_DIR="/usr/share/hypercube/config"

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

### zellij multiplexer - system default config
# zellij doesn't honor XDG_CONFIG_DIRS (like fish), so its config can't live in
# /usr/share/hypercube/config. Install the unified keymap as the system default
# at /etc/zellij; users override it at ~/.config/zellij/config.kdl.
install -Dm644 "${CONFIG_DIR}/zellij/config.kdl" /etc/zellij/config.kdl

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

### Alacritty terminal - stub that imports system config
# Alacritty coexists with Ghostty (Ghostty stays the default terminal).
# Users can customize by adding settings after the import line.
mkdir -p /etc/skel/.config/alacritty
cat > /etc/skel/.config/alacritty/alacritty.toml << 'EOF'
# Hypercube Alacritty Configuration
# System defaults are imported below. Add your customizations after this line.
# To replace defaults entirely, remove or comment out the import.

[general]
import = ["/usr/share/hypercube/config/alacritty/alacritty.toml"]

# Your customizations below:
EOF

### niri - system config stub that includes the Hypercube defaults
# niri doesn't honor XDG_CONFIG_DIRS. It reads ~/.config/niri/config.kdl and
# falls back to /etc/niri/config.kdl, so install a stub there that includes
# the always-current defaults from /usr/share/hypercube/config/niri.
# Users customize by creating ~/.config/niri/config.kdl with the same include
# line followed by their overrides (settings after an include override it).
install -d /etc/niri
cat > /etc/niri/config.kdl << 'EOF'
// Hypercube niri configuration
// System defaults are included below. To customize, copy this file to
// ~/.config/niri/config.kdl and add your settings after the include line.

include "/usr/share/hypercube/config/niri/config.kdl"
EOF

### swaylock / swayidle - system defaults
# Neither honors XDG_CONFIG_DIRS (like zellij), so install the Hypercube
# defaults to /etc. Users override with ~/.config/swaylock/config and
# ~/.config/swayidle/config, which replace these files entirely.
install -Dm644 "${CONFIG_DIR}/swaylock/config" /etc/swaylock/config
install -Dm644 "${CONFIG_DIR}/swayidle/config" /etc/swayidle/config

### Neovim - devcube sandbox overrides
# The editor config + AI agents ship baked into the devcube podman image
# (ujust devcube-setup). Users keep ONLY personal plugin overrides here; this
# directory is bind-mounted into the container's baked LazyVim config and
# layered on top of it.
mkdir -p /etc/skel/.config/hypercube/nvim/lua/plugins
cat > /etc/skel/.config/hypercube/nvim/lua/plugins/example.lua << 'EOF'
-- Personal Neovim overrides
-- These are layered on top of Hypercube's baked LazyVim configuration.
--
-- To add a new plugin:
--   return {
--     "username/plugin-name",
--     opts = { ... },
--   }
--
-- To override a Hypercube plugin:
--   return {
--     "folke/snacks.nvim",
--     opts = {
--       dashboard = {
--         preset = { header = "Your custom header" },
--       },
--     },
--   }
--
-- To disable a plugin:
--   return {
--     "plugin/name",
--     enabled = false,
--   }

return {}
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

### Default browser / URL handler
# Register Firefox as the default for http/https so xdg-open works (Ghostty
# "open link", agy/claude OAuth logins, any CLI that opens a browser). Installed
# to /usr/share/applications/ (the data-dir default every opener honors); the
# same file is also reachable via XDG_CONFIG_DIRS at /usr/share/hypercube/config.
install -Dm644 "${CONFIG_DIR}/mimeapps.list" /usr/share/applications/mimeapps.list

### Enable xdg-desktop-portal-gtk for dark mode detection (Firefox, etc.)
# This portal provides the org.freedesktop.appearance.color-scheme setting
systemctl --global enable xdg-desktop-portal-gtk.service

echo "Hypercube configurations installed successfully"
