#!/bin/bash
# Hypercube Gaming
# Steam and gaming utilities from negativo17

set -ouex pipefail

echo "Installing gaming packages..."

### Add negativo17 Steam repository
dnf5 -y config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-steam.repo

### Install Steam
dnf5 -y --setopt=install_weak_deps=False install steam

### Disable negativo17 repo after install (prevent user from layering packages)
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-steam.repo

echo "Gaming packages installed successfully"
