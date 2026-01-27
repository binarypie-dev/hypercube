#!/bin/bash
# Hypercube Validation Tests
# Verifies that the build was successful

set -ouex pipefail

echo "Running Hypercube validation tests..."

### Check critical packages are installed
REQUIRED_PACKAGES=(
  # Display manager
  "greetd"
  "cage"
  "hypercube-utils"
  # Hyprland stack
  "hyprland"
  "hyprlock"
  "hypridle"
  "quickshell"
  # Terminals
  "ghostty"
  # Dev tools
  "neovim"
  "lazygit"
  "fish"
  "starship"
  "wifitui"
  # DX tooling
  "distrobox"
  "podman"
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
  # Branding
  "/usr/share/hypercube/image-info.json"
  "/usr/lib/environment.d/60-hypercube-xdg.conf"
  # greetd
  "/etc/greetd/config.toml"
  # Config files
  "/etc/fish/config.fish"
  "/usr/share/hypercube/config/starship/starship.toml"
  # Theming
  "/usr/share/themes/Tokyonight-Dark/gtk-3.0/gtk.css"
  "/usr/share/icons/Tokyonight-Dark/index.theme"
  "/usr/share/plymouth/themes/hypercube/hypercube.plymouth"
  "/usr/share/pixmaps/hypercube-logo.png"
  "/usr/share/backgrounds/hypercube/background.png"
  # DX config
  "/etc/distrobox/distrobox.ini"
  "/usr/share/ublue-os/just/60-hypercube.just"
  "/usr/share/ublue-os/just/61-nvim.just"
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

### Check services are enabled
REQUIRED_SERVICES=(
  "greetd.service"
  "NetworkManager.service"
)

for svc in "${REQUIRED_SERVICES[@]}"; do
  if ! systemctl is-enabled "$svc" &>/dev/null; then
    echo "ERROR: Required service '$svc' is not enabled!"
    exit 1
  fi
  echo "  OK: $svc enabled"
done

echo "All Hypercube validation tests passed!"
