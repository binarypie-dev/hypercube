#!/bin/bash
set -euxo pipefail

# Hypercube ISO Live Session Setup
# Since livesys-scripts doesn't support Hyprland yet, we do the setup manually
#
# NOTE: This script runs inside titanoboa's chroot with livesys=0
#
# TODO: Once https://pagure.io/livesys-scripts merges Hyprland support,
#       we can remove this and use livesys=1

echo "Setting up Hypercube live session..."

### Install livesys-scripts (we'll run the Hyprland session setup manually)
dnf5 -y install livesys-scripts

### Configure livesys for Hyprland
sed -i 's/^livesys_session=.*/livesys_session=hyprland/' /etc/sysconfig/livesys

### Install Hyprland session file for livesys-scripts
mkdir -p /usr/libexec/livesys/sessions.d
cat > /usr/libexec/livesys/sessions.d/livesys-hyprland << 'SESSION_EOF'
#!/bin/sh
#
# livesys-hyprland: hyprland specific setup for livesys
# SPDX-License-Identifier: GPL-3.0-or-later
#

HYPRLAND_SESSION_FILE="hyprland.desktop"

# set up autologin for user liveuser using greetd
if [ -f /etc/greetd/config.toml ]; then
    cat > /etc/greetd/config.toml << GREETD_EOF
[terminal]
vt = 1

[default_session]
command = "Hyprland"
user = "liveuser"
GREETD_EOF
fi

# Show harddisk install on the desktop
if [ -f /usr/share/applications/liveinst.desktop ]; then
    sed -i -e 's/NoDisplay=true/NoDisplay=false/' /usr/share/applications/liveinst.desktop
fi
mkdir -p /home/liveuser/Desktop
SESSION_EOF

chmod +x /usr/libexec/livesys/sessions.d/livesys-hyprland

### Enable livesys services
systemctl enable livesys.service livesys-late.service

### Create livesys-session-extra tmpfiles config
echo "C /var/lib/livesys/livesys-session-extra 0755 root root - /usr/share/factory/var/lib/livesys/livesys-session-extra" > \
    /usr/lib/tmpfiles.d/livesys-session-extra.conf

### Mark this as a live session
mkdir -p /var/lib/hypercube
touch /var/lib/hypercube/live-session

echo "Hypercube live session setup complete"
