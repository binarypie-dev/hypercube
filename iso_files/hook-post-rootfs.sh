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

# Update BUG_REPORT_URL to point to Hypercube GitHub issues
sed -i 's|^BUG_REPORT_URL=.*|BUG_REPORT_URL="https://github.com/binarypie-dev/hypercube/issues"|' /usr/lib/os-release

# Install Anaconda profile for Hypercube
mkdir -p /etc/anaconda/profile.d/
install -m 0644 "${ISO_FILES}/anaconda/hypercube.conf" /etc/anaconda/profile.d/hypercube.conf

# Create Anaconda pixmaps directory for Hypercube branding
mkdir -p /usr/share/anaconda/pixmaps/hypercube/

# Install Anaconda CSS theme (Tokyo Night)
install -m 0644 "${ISO_FILES}/anaconda/hypercube.css" /usr/share/anaconda/pixmaps/hypercube/hypercube.css

# Copy Plymouth spinner frames for Anaconda loading animation (if available)
if [[ -d /usr/share/plymouth/themes/hypercube ]]; then
    cp /usr/share/plymouth/themes/hypercube/animation-*.png /usr/share/anaconda/pixmaps/hypercube/ 2>/dev/null || true
fi

# Create live ISO hyprland config directory
mkdir -p /usr/share/hypr/config.live.d/

# Copy Hyprland live configs (ensure readable by all users)
install -m 0644 "${ISO_FILES}/hypr/hyprland-live.conf" /usr/share/hypr/config.live.d/hyprland.conf
install -m 0644 "${ISO_FILES}/hypr/hyprpaper-live.conf" /usr/share/hypr/config.live.d/hyprpaper.conf

# Copy background image for live ISO
install -m 0644 "${ISO_FILES}/branding/background.png" /usr/share/hypr/config.live.d/background.png

# Configure livesys to use the hyprland session
# The livesys-hyprland script is already provided by livesys-scripts from binarypie/hypercube COPR
sed -i 's/^livesys_session=.*/livesys_session=hyprland/' /etc/sysconfig/livesys
# If the line doesn't exist, add it
grep -q '^livesys_session=' /etc/sysconfig/livesys || echo 'livesys_session=hyprland' >> /etc/sysconfig/livesys

echo "Hypercube post-rootfs hook completed successfully"
