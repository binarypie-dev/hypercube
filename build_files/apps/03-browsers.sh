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
# Follows Brave's Fedora Atomic instructions: add the official RPM repo, then
# install with rpm-ostree. Brave installs into /opt, which on ostree/bootc
# systems is a symlink to /var/opt (not shipped in the image). rpm-ostree's
# "optfix" relocates those files into /usr/lib/opt and symlinks them back at
# boot, so this must NOT use dnf5 (which fails to unpack into /opt at build).

### Add Brave's official RPM repository and import its package signing key
curl -fsSLo /etc/yum.repos.d/brave-browser.repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

### Install Brave Origin (rpm-ostree handles the /opt relocation)
rpm-ostree install brave-origin

### Disable the Brave repo after install (prevent user from layering packages;
### browser updates arrive with image rebuilds)
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/brave-browser.repo

echo "Browsers installed successfully"
