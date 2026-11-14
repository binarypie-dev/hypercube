#!/bin/bash
# Hypercube Desktop Stack
# Installs the niri compositor, session services, terminals, editors and tools.
# niri config lives in dot_files/niri (installed by 03-hypercube-configs.sh).
#
# The greeter lists niri from /usr/share/wayland-sessions/niri.desktop
# (Exec=niri-session), which runs niri as a systemd user service
# (niri.service); session services such as the polkit agent hang off it.

set -ouex pipefail

echo "Installing desktop stack..."

### Compositor - niri
# Skip weak deps: niri recommends waybar and fuzzel as a starter
# desktop, which Quickshell replaces here. Every recommend we do
# want (portals, gnome-keyring, swaylock, wireplumber, alacritty) is installed explicitly
# below or already comes from the base phase.
dnf5 -y --setopt=install_weak_deps=False install \
  niri \
  xwayland-satellite \
  xdg-desktop-portal-gnome

### Session services
# swaybg     - wallpaper (layer shell, works on any wlroots-style compositor)
# swaylock   - lock screen (ships /etc/pam.d/swaylock)
# swayidle   - idle management: dim, lock, DPMS, suspend
# mate-polkit - polkit authentication agent. Without a running agent nothing
#               can ask for the admin password, so udisks (unlocking LUKS
#               drives in Nautilus / GNOME Disks), pkexec, flatpak system
#               installs etc. just fail with "Not authorized". Started by
#               hypercube-polkit-agent.service (system_files), not niri.
# brightnessctl / playerctl - used by the niri media/brightness keybindings
#               and the swayidle dimming timers
dnf5 -y install \
  swaybg \
  swaylock \
  swayidle \
  mate-polkit \
  brightnessctl \
  playerctl

# Start the polkit agent with every niri session
systemctl --global enable hypercube-polkit-agent.service

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
  lazygit \
  wifitui \
  bluetui \
  yazi \
  resvg

### Fish Shell (set as default)
dnf5 -y install fish

### Terminal multiplexer - zellij (from Hypercube COPR)
# Gives the host the same Ctrl+Space multiplexer keymap (installed to
# /etc/zellij/config.kdl by 03-hypercube-configs.sh) as devcube.
dnf5 -y install zellij

### Terminal - Ghostty (from scottames COPR)
dnf5 -y copr enable scottames/ghostty
dnf5 -y install ghostty

### Terminal - Alacritty (from Hypercube COPR)
# Ghostty stays the default terminal; Alacritty is available alongside it.
# Terminfo (alacritty + alacritty-direct) ships inside the RPM.
dnf5 -y install alacritty

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

echo "Desktop stack installed successfully"
