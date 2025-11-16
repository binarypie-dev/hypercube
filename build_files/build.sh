#!/bin/bash

set -ouex pipefail

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
dnf5 -y install fd-find

# Remove extra things
# TODO: Figure out what we don't need from solopasha/hyprland

# Application Launcher - Walker / Elephant
# Build from source in this layer to save disk space

# Build Elephant (Go-based)
echo "Building Elephant..."
dnf5 -y install git golang protobuf-compiler

# Clone Elephant repository
ELEPHANT_VERSION="v2.15.0"
git clone --depth 1 --branch ${ELEPHANT_VERSION} https://github.com/abenz1267/elephant.git /tmp/elephant

cd /tmp/elephant

# Set Go environment variables for build
export GOPATH=/tmp/go
export GOCACHE=/tmp/go-cache
export GOTOOLCHAIN=auto
export GOSUMDB=sum.golang.org

# Build Elephant
cd cmd/elephant
go build -o elephant elephant.go

# Install binary
install -Dm755 elephant /usr/bin/elephant

# Create systemd user service directory
mkdir -p /usr/lib/systemd/user

# Create systemd service file
cat > /usr/lib/systemd/user/elephant.service << 'EOF'
[Unit]
Description=Elephant Data Provider Service
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/elephant
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

# Clean up Elephant build
cd /
rm -rf /tmp/elephant /tmp/go /tmp/go-cache

echo "Elephant build complete."

# Build Walker (Rust-based with GTK4)
echo "Building Walker..."
dnf5 -y install rust cargo gtk4-devel gtk4-layer-shell-devel cairo-devel poppler-glib-devel

# Clone Walker repository
WALKER_VERSION="v2.10.0"
git clone --depth 1 --branch ${WALKER_VERSION} https://github.com/abenz1267/walker.git /tmp/walker

cd /tmp/walker

# Set Cargo environment variables for build
export CARGO_HOME=/tmp/cargo
export CARGO_TARGET_DIR=/tmp/cargo-target

# Build Walker with release optimizations
cargo build --release

# Install binary
install -Dm755 /tmp/cargo-target/release/walker /usr/bin/walker

# Install desktop file if it exists
if [ -f resources/walker.desktop ]; then
    install -Dm644 resources/walker.desktop /usr/share/applications/walker.desktop
fi

# Install default resources
mkdir -p /usr/share/walker
if [ -d resources ]; then
    cp -r resources/* /usr/share/walker/ || true
fi

# Clean up Walker build
cd /
rm -rf /tmp/walker /tmp/cargo /tmp/cargo-target

# Remove build dependencies to keep layer small
dnf5 -y remove golang rust cargo protobuf-compiler
dnf5 -y clean all

echo "Walker build complete."

# On Screen Display
dnf5 -y copr enable markupstart/SwayOSD
dnf5 -y install swayosd

# Desktop Notifications
dnf5 -y install mako
systemctl --global mask mako.service

# Terminals
dnf5 -y copr enable wezfurlong/wezterm-nightly
dnf5 -y install wezterm

dnf -y copr enable scottames/ghostty
dnf -y install ghostty

# Editor
dnf5 -y copr enable agriffis/neovim-nightly
dnf5 -y install neovim python3-neovim

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
