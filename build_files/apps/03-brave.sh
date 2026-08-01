#!/bin/bash
# Hypercube Brave Origin
# Brave Origin browser from Brave's official RPM repository
#
# Brave Origin is the minimalist Brave experience (Shields ad blocking and
# privacy, without Rewards/Leo/VPN), free on Linux. It ships from Brave's
# official RPM repo as its own `brave-origin` package.
# https://brave.com/origin/linux/

set -ouex pipefail

echo "Installing Brave Origin..."

### Add Brave's official RPM repository
dnf5 -y config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo

### Import Brave's package signing key so dnf can verify the RPM
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

### Install Brave Origin
dnf5 -y install brave-origin

### Disable the Brave repo after install (prevent user from layering packages;
### browser updates arrive with image rebuilds)
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/brave-browser.repo

echo "Brave Origin installed successfully"
