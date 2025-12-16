#!/bin/bash
set -euxo pipefail

# Hide Hyprland session so livesys detects GNOME for the live session
# After install, the full image with Hyprland session will be deployed
# This runs before rootfs-install-livesys-scripts
if [ -f /usr/share/wayland-sessions/hyprland.desktop ]; then
    mv /usr/share/wayland-sessions/hyprland.desktop /usr/share/wayland-sessions/hyprland.desktop.hidden
    echo "Hyprland session hidden - livesys will detect GNOME instead"
fi
