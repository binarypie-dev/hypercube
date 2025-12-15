#!/bin/bash
# Hypercube Validation Tests
# Verifies that the build was successful

set -ouex pipefail

echo "Running Hypercube validation tests..."

### Check critical packages are installed
REQUIRED_PACKAGES=(
    "hyprland"
    "hyprlock"
    "hypridle"
    "quickshell"
    "wezterm"
    "ghostty"
    "neovim"
    "lazygit"
)

for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! rpm -q "$pkg" &>/dev/null; then
        echo "ERROR: Required package '$pkg' is not installed!"
        exit 1
    fi
    echo "  OK: $pkg installed"
done

### Check critical files exist
REQUIRED_FILES=(
    "/usr/share/hypercube/image-info.json"
    "/usr/lib/environment.d/60-hypercube-xdg.conf"
    "/usr/bin/nvimd"
    "/etc/fish/config.fish"
    "/usr/share/hypercube/config/starship/starship.toml"
    "/usr/share/themes/Tokyonight-Dark/gtk-3.0/gtk.css"
    "/usr/share/icons/Tokyonight-Dark/index.theme"
    "/usr/share/plymouth/themes/hypercube/hypercube.plymouth"
    "/usr/share/pixmaps/hypercube-logo.png"
    "/usr/share/backgrounds/hypercube/background.png"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -e "$file" ]; then
        echo "ERROR: Required file '$file' does not exist!"
        exit 1
    fi
    echo "  OK: $file exists"
done

### Check os-release branding
if ! grep -q "ID=hypercube" /usr/lib/os-release; then
    echo "ERROR: os-release branding not applied!"
    exit 1
fi
echo "  OK: os-release branding applied"

echo "All Hypercube validation tests passed!"
