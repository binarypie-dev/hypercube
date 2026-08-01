#!/bin/bash
# Hypercube Browsers
# Web browsers beyond the base Firefox install.
#
# Brave Origin is the minimalist Brave experience (Shields ad blocking and
# privacy, without Rewards/Leo/VPN), free on Linux. It ships from Brave's
# official RPM repo as its own `brave-origin` package.
# https://brave.com/origin/linux/

set -ouex pipefail

echo "Installing browsers..."

### Brave Origin ###############################################################

### Add Brave's official RPM repository and import its package signing key
dnf5 -y config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

### Brave installs into /opt, which on ostree/bootc systems is a symlink to
### /var/opt. /var is not shipped in the image, so a plain dnf5 install fails to
### unpack the RPM ("cpio: mkdir failed"). rpm-ostree solves this at runtime with
### "optfix"; replicate it at build time: point /opt at /usr/lib/opt (which IS
### shipped) for the install, restore the original symlink, then recreate the
### /opt/brave.com path at boot via tmpfiles.
mkdir -p /usr/lib/opt
orig_opt="$(readlink /opt || true)"
rm -f /opt
ln -s usr/lib/opt /opt

dnf5 -y install brave-origin

### Restore the ostree-standard /opt -> var/opt symlink for runtime
rm -f /opt
ln -s "${orig_opt:-var/opt}" /opt

### Recreate /opt/brave.com (via /var/opt) -> /usr/lib/opt/brave.com at boot
cat >/usr/lib/tmpfiles.d/brave-origin-opt.conf <<'EOF'
d /var/opt 0755 root root - -
L /var/opt/brave.com - - - - /usr/lib/opt/brave.com
EOF

### Disable the Brave repo after install (prevent user from layering packages;
### browser updates arrive with image rebuilds)
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/brave-browser.repo

echo "Browsers installed successfully"
