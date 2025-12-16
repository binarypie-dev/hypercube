#!/bin/bash
# Hypercube Hyprland Desktop Stack
# Installs Hyprland compositor, tools, terminals, and editors

set -ouex pipefail

echo "Installing Hyprland desktop stack..."

### Compositor / Hyprland Stack
dnf5 -y copr enable sdegler/hyprland
dnf5 -y install \
    hyprland \
    hyprland-contrib \
    hyprland-plugins \
    hyprland-qtutils \
    hyprpaper \
    hyprpicker \
    hypridle \
    hyprshot \
    hyprlock \
    hyprpolkitagent \
    pyprland \
    waybar-git \
    xdg-desktop-portal-hyprland

### Quickshell - Application Launcher, Notifications, OSD
dnf5 -y copr enable errornointernet/quickshell
dnf5 -y install quickshell

### CLI Tools - Official Fedora repos
dnf5 -y install \
    fd-find \
    fzf \
    ripgrep \
    bat \
    zoxide \
    htop \
    btop \
    git \
    jq \
    yq \
    tmux \
    qt6ct

### CLI Tools - From COPRs (not in official F43 repos)
# eza - modern ls replacement
dnf5 -y copr enable alternateved/eza
dnf5 -y install eza

# starship - cross-shell prompt
dnf5 -y copr enable atim/starship
dnf5 -y install starship

# git-delta - better git diff
dnf5 -y copr enable gourlaysama/git-delta || true
dnf5 -y install git-delta || true

### Fish Shell (set as default)
# Note: fisher (plugin manager) removed - starship handles prompt, fish has good built-in completions
dnf5 -y install fish

### Lazygit from COPR
dnf5 -y copr enable atim/lazygit
dnf5 -y install lazygit

### Terminals
dnf5 -y copr enable wezfurlong/wezterm-nightly
dnf5 -y install wezterm

dnf5 -y copr enable scottames/ghostty
dnf5 -y install ghostty

### Editor
dnf5 -y copr enable agriffis/neovim-nightly
dnf5 -y install neovim python3-neovim

### Image/Media Viewers
dnf5 -y install \
    imv \
    mpv

### Screenshot/Screen Recording (hyprshot handles most, but add deps)
dnf5 -y install \
    grim \
    slurp

echo "Hyprland desktop stack installed successfully"
