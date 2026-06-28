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

### zellij multiplexer - system default config + local copy
# zellij doesn't honor XDG_CONFIG_DIRS (like fish), so its config can't live in
# /usr/share/hypercube/config. Install the unified keymap as the system default
# at /etc/zellij as a base fallback.
# For the full local experience (config.kdl + layouts/, matching the devcube
# container), the baked config is also copied into ~/.config/zellij on login by
# /usr/libexec/hypercube/sync-local-config (see fish/conf.d/20-local-config.fish);
# that user copy takes precedence over /etc/zellij.
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

### Neovim - local config + personal overrides
# Two ways to run the same LazyVim config:
#   * Locally on the host: /usr/libexec/hypercube/sync-local-config copies the
#     baked config (/usr/share/hypercube/config/nvim/config) into ~/.config/nvim
#     on login (see fish/conf.d/20-local-config.fish), so a plain `nvim` is
#     preconfigured. nvim can't read the baked path directly (it ignores
#     XDG_CONFIG_DIRS for its init), hence the copy.
#   * Inside the devcube podman image (ujust devcube-setup), where the AI agents
#     also live.
# Either way, personal plugin overrides live ONLY in the dir below; it's layered
# on top of the baked LazyVim config (locally via runtimepath, and bind-mounted
# into the container) — see nvim/config/lua/config/lazy.lua.
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
