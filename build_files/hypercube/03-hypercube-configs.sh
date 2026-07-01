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

### zellij multiplexer - system default config + skel copy
# zellij doesn't honor XDG_CONFIG_DIRS (like fish), so its config can't live in
# /usr/share/hypercube/config. Install the unified keymap as the system default
# at /etc/zellij so a bare user still gets it.
install -Dm644 "${CONFIG_DIR}/zellij/config.kdl" /etc/zellij/config.kdl
# zellij has no config "import"/source directive (unlike nvim/ghostty/hyprland),
# so for the full local experience -- the layouts/ (e.g. the workmux layout) that
# /etc/zellij can't provide -- ship the whole config into /etc/skel. New users get
# it; existing users copy it with `cp -r /etc/skel/.config/zellij ~/.config/`.
# This user copy takes precedence over /etc/zellij.
mkdir -p /etc/skel/.config/zellij
cp -r "${CONFIG_DIR}/zellij/." /etc/skel/.config/zellij/

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

### Neovim - skel stub that imports the baked config
# nvim ignores XDG_CONFIG_DIRS for its init, so it can't read the baked config
# straight from /usr/share/hypercube/config. Instead, drop a thin init.lua stub
# in /etc/skel that points nvim at the baked LazyVim config (the same one baked
# into the devcube container) -- mirroring the ghostty/hyprland config stubs
# above. Because the stub references the read-only /usr/share path, config
# updates ship with the OS image; only the tiny stub lives in the user's config.
# New users get it; existing users copy it with
# `cp -r /etc/skel/.config/nvim ~/.config/`.
mkdir -p /etc/skel/.config/nvim
cat > /etc/skel/.config/nvim/init.lua << 'EOF'
-- Hypercube Neovim configuration.
-- The real config is image-owned and read-only at the path below; it updates
-- with the OS image. This stub just points Neovim at it (like the ghostty and
-- hyprland config stubs). Personal plugin overrides go in
-- ~/.config/hypercube/nvim/lua/plugins/ -- they're layered on top, NOT here.
local baked = "/usr/share/hypercube/config/nvim/config"
vim.opt.runtimepath:prepend(baked)
dofile(baked .. "/init.lua")
EOF

### Neovim - personal overrides
# Personal plugin specs live ONLY in the dir below; they're layered on top of the
# baked LazyVim config (locally via runtimepath, and bind-mounted into the
# devcube container) -- see nvim/config/lua/config/lazy.lua.
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
