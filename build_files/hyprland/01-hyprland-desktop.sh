#!/bin/bash
# Hypercube Hyprland Desktop Stack
# Installs Hyprland compositor, tools, terminals, and editors

set -ouex pipefail

echo "Installing Hyprland desktop stack..."

### Compositor / Hyprland Stack 
dnf5 -y install \
  hyprland \
  hyprland-guiutils \
  hyprland-uwsm \
  hyprpaper \
  hypridle \
  hyprlock \
  hyprpolkitagent \
  xdg-desktop-portal-hyprland

### Quickshell - Application Launcher, Notifications, OSD (from Hypercube COPR)
dnf5 -y install quickshell

### Datacube - System management CLI (from Hypercube COPR)
dnf5 -y install --refresh datacube

# Enable datacube user service for all users
# Creates symlink so service auto-starts on user login
mkdir -p /etc/systemd/user/default.target.wants
ln -sf /usr/lib/systemd/user/datacube.service /etc/systemd/user/default.target.wants/datacube.service

### CLI Tools - Official Fedora repos
dnf5 -y install \
  fd-find \
  fzf \
  ripgrep \
  bat \
  zoxide \
  htop \
  btop \
  git \
  jq \
  yq \
  tmux \
  qt6ct

### CLI Tools - From Hypercube COPR
dnf5 -y install \
  eza \
  starship \
  lazygit

### Fish Shell (set as default)
dnf5 -y install fish

### Terminal - Ghostty (from scottames COPR)
dnf5 -y copr enable scottames/ghostty
dnf5 -y install ghostty

### Editor - Neovim nightly (from agriffis COPR)
dnf5 -y copr enable agriffis/neovim-nightly
dnf5 -y install neovim python3-neovim

### Image/Media Viewers
dnf5 -y install \
  imv \
  mpv

### Screenshot/Screen Recording
dnf5 -y install \
  grim \
  slurp

echo "Hyprland desktop stack installed successfully"
