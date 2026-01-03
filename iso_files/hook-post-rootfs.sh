#!/bin/bash
# Hypercube Live ISO post-rootfs hook
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This script runs inside the rootfs before it gets squashed into the ISO.
# Files are available at /app/iso_files/ (copied from hypercube project)

set -xeuo pipefail

ISO_FILES="/app/iso_files"

# Verify iso_files are available
if [[ ! -d "${ISO_FILES}" ]]; then
    echo "ERROR: iso_files not found at ${ISO_FILES}"
    echo "Make sure iso_files directory is copied to _titanoboa before building"
    exit 1
fi

# Install Anaconda installer (Fedora's default installer)
dnf install -y anaconda anaconda-live

# Install netcat for log sharing support
dnf install -y nmap-ncat

# Configure Anaconda to use ostreecontainer instead of live image rsync
# This is required for bootc/ostree-based systems
# Get the embedded container image name from podman storage
CONTAINER_IMAGE=$(podman images --format '{{.Repository}}:{{.Tag}}' | head -1)
if [[ -n "${CONTAINER_IMAGE}" ]]; then
    echo "Configuring Anaconda to install from container: ${CONTAINER_IMAGE}"

    # Add ostreecontainer command to interactive-defaults.ks
    # This tells Anaconda to deploy the container image instead of rsync'ing the live filesystem
    # The container image reference stored in podman will be whatever was used to build the ISO:
    # - Local builds: your local registry (e.g., 10.0.7.113:5000/hypercube:stable-daily)
    # - GitHub Actions: ghcr.io/binarypie-dev/hypercube:latest
    # Using containers-storage transport means it uses the locally embedded image regardless of name
    cat >> /usr/share/anaconda/interactive-defaults.ks << EOF
# Hypercube: Install from embedded container image using ostreecontainer
ostreecontainer --url=${CONTAINER_IMAGE} --transport=containers-storage --no-signature-verification --stateroot=hypercube
EOF
else
    echo "WARNING: No container image found in podman storage"
    echo "Installation may fail - ensure container is embedded during ISO build"
fi

# Update BUG_REPORT_URL to point to Hypercube GitHub issues
sed -i 's|^BUG_REPORT_URL=.*|BUG_REPORT_URL="https://github.com/binarypie-dev/hypercube/issues"|' /usr/lib/os-release

# Install Anaconda profile for Hypercube
mkdir -p /etc/anaconda/profile.d/
install -m 0644 "${ISO_FILES}/anaconda/hypercube.conf" /etc/anaconda/profile.d/hypercube.conf

# Create Anaconda pixmaps directory for Hypercube branding
mkdir -p /usr/share/anaconda/pixmaps/hypercube/

# Install Anaconda CSS theme (Tokyo Night)
install -m 0644 "${ISO_FILES}/anaconda/hypercube.css" /usr/share/anaconda/pixmaps/hypercube/hypercube.css

# Install Hypercube sidebar logo for installer branding
install -m 0644 "${ISO_FILES}/anaconda/sidebar-logo.png" /usr/share/anaconda/pixmaps/hypercube/sidebar-logo.png

# Copy Plymouth spinner frames for Anaconda loading animation (if available)
if [[ -d /usr/share/plymouth/themes/hypercube ]]; then
    cp /usr/share/plymouth/themes/hypercube/animation-*.png /usr/share/anaconda/pixmaps/hypercube/ 2>/dev/null || true
fi

# Copy base image Hyprland configs for live environment
# This gives users the full Hypercube experience to test before installing
if [[ -d /usr/share/hypercube/config/hypr ]]; then
    mkdir -p /usr/share/hypr/config.live.d/
    cp /usr/share/hypercube/config/hypr/* /usr/share/hypr/config.live.d/

    # Add live environment configuration
    cat >> /usr/share/hypr/config.live.d/hyprland.conf << 'EOF'

# Live ISO - Environment variables for XDG config discovery
# These are normally set by systemd user session but greetd skips that
env = XDG_CONFIG_DIRS,/etc/xdg:/usr/share/hypercube/config
env = XDG_DATA_DIRS,/usr/local/share:/usr/share:/usr/share/hypercube/data
env = GTK_THEME,Tokyonight-Dark
env = QT_QPA_PLATFORMTHEME,qt6ct

# Live ISO - Window rules for Anaconda installer
# Prevent fullscreen, keep as tiled window so user can access terminal
windowrule = tile, class:^(anaconda)$
windowrule = tile, class:^(liveinst)$
windowrule = noinitialfocus, class:^(anaconda)$
windowrule = noinitialfocus, class:^(liveinst)$

# Live ISO - Auto-launch installer
exec-once = liveinst
EOF
fi

# Configure livesys to use the hyprland session
# The livesys-hyprland script is already provided by livesys-scripts from binarypie/hypercube COPR
sed -i 's/^livesys_session=.*/livesys_session=hyprland/' /etc/sysconfig/livesys
# If the line doesn't exist, add it
grep -q '^livesys_session=' /etc/sysconfig/livesys || echo 'livesys_session=hyprland' >> /etc/sysconfig/livesys

# Disable services that shouldn't run in live environment
# These are update/setup services that don't make sense on live media
systemctl disable rpm-ostree-countme.service || true
systemctl disable bootloader-update.service || true
systemctl disable rpm-ostreed-automatic.timer || true
# flatpak-preinstall is now a user service, no need to disable
systemctl disable hypercube-first-boot.service || true

# Disable services that fail in live environment
systemctl disable mcelog.service || true
systemctl disable ublue-nvctk-cdi.service || true
systemctl disable systemd-modules-load.service || true

echo "Hypercube post-rootfs hook completed successfully"
