#!/bin/bash
# Hypercube niri session
# Installs niri as an alternative session next to Hyprland. It runs the same
# Quickshell shell, hyprlock, hypridle and hyprpolkitagent as the Hyprland
# session; config lives in dot_files/niri (see 03-hypercube-configs.sh).
#
# The greeter lists niri from /usr/share/wayland-sessions/niri.desktop
# (Exec=niri-session). Hyprland (uwsm) stays the default session.

set -ouex pipefail

echo "Installing niri session..."

# Skip weak deps: niri recommends waybar, fuzzel and swaylock as a
# starter desktop, which Quickshell and hyprlock replace here. The recommends
# we do want (portals, gnome-keyring, wireplumber) are installed explicitly or
# already come from the base image.
dnf5 -y --setopt=install_weak_deps=False install \
  niri \
  xwayland-satellite \
  swaybg \
  xdg-desktop-portal-gnome

echo "niri session installed successfully"
