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

### Install Lutris (open gaming platform / game manager) from Fedora repos
### Keep weak deps: Lutris relies on its recommends (wine, gamemode, mangohud,
### vulkan tooling, etc.) for the runtimes it manages
###
### Lutris shells out to `xrandr` unconditionally at startup to enumerate
### display resolutions; without the binary it crashes (xrandr -> None ->
### TypeError). It also probes `vulkaninfo` for GPU/Vulkan detection. Neither
### is pulled in on this Wayland-first image, so install them explicitly.
### xrandr works under the XWayland already provided by Hyprland.
dnf5 -y install \
    lutris \
    vulkan-tools \
    xrandr

echo "Gaming packages installed successfully"
