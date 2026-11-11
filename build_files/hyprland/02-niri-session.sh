#!/bin/bash
# Hypercube niri session
# Installs niri as an alternative session next to Hyprland. It runs the same
# Quickshell shell as the Hyprland session but its own session services
# (swaylock, swayidle, mate-polkit) so it doesn't depend on any Hyprland
# tools; config lives in dot_files/niri (see 03-hypercube-configs.sh).
#
# The greeter lists niri from /usr/share/wayland-sessions/niri.desktop
# (Exec=niri-session). Hyprland (uwsm) stays the default session.

set -ouex pipefail

echo "Installing niri session..."

# Skip weak deps: niri recommends waybar, fuzzel and swaylock as a
# starter desktop, which Quickshell replaces here. The recommends we do want
# (portals, gnome-keyring, swaylock, wireplumber) are installed explicitly or
# already come from the base image.
dnf5 -y --setopt=install_weak_deps=False install \
  niri \
  xwayland-satellite \
  swaybg \
  xdg-desktop-portal-gnome

### niri session services (no Hyprland tools)
# swaylock    - lock screen (ships /etc/pam.d/swaylock)
# swayidle    - idle management: dim, lock, DPMS, suspend
# mate-polkit - polkit authentication agent. Without a running agent nothing
#               can ask for the admin password, so udisks (unlocking LUKS
#               drives in Nautilus / GNOME Disks), pkexec, system flatpak
#               installs etc. fail with "Not authorized". Started by
#               hypercube-polkit-agent.service, which only runs with niri.
# brightnessctl / playerctl - used by the niri keybindings and idle timers
dnf5 -y install \
  swaylock \
  swayidle \
  mate-polkit \
  brightnessctl \
  playerctl

# Start the polkit agent with every niri session
systemctl --global enable hypercube-polkit-agent.service

echo "niri session installed successfully"
