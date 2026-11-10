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
  # niri session
  "niri"
  "xwayland-satellite"
  "swaybg"
  "xdg-desktop-portal-gnome"
  # Terminals
  "ghostty"
  "zellij"
  # Dev tools
  "neovim"
  "lazygit"
  "fish"
  "starship"
  "wifitui"
  # DX tooling
  "distrobox"
  "podman"
  # Browser
  "brave-origin"
  # Gaming
  "steam"
  "lutris"
  "vulkan-tools" # vulkaninfo, used by Lutris for GPU detection
  "xrandr"       # required by Lutris at startup to enumerate resolutions
  # Kernel modules
  "kmod-v4l2loopback"
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
  "/etc/zellij/config.kdl"
  "/usr/share/hypercube/config/starship/starship.toml"
  "/etc/niri/config.kdl"
  "/usr/share/hypercube/config/niri/config.kdl"
  "/usr/share/hypercube/config/niri/hypridle.conf"
  "/usr/share/hypercube/config/xdg-desktop-portal/niri-portals.conf"
  "/usr/share/wayland-sessions/niri.desktop"
  # Theming
  "/usr/share/themes/Tokyonight-Dark/gtk-3.0/gtk.css"
  "/usr/share/icons/Tokyonight-Dark/index.theme"
  "/usr/share/plymouth/themes/hypercube/hypercube.plymouth"
  "/usr/share/pixmaps/hypercube-logo.png"
  "/usr/share/backgrounds/hypercube/background.png"
  # DX config
  "/etc/distrobox/distrobox.ini"
  "/usr/share/ublue-os/just/60-hypercube.just"
  "/usr/share/ublue-os/just/61-devcube.just"
  # Flatpaks are installed on the machine, not baked into the image
  "/usr/share/flatpak/preinstall.d/hypercube.preinstall"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -e "$file" ]; then
    echo "ERROR: Required file '$file' does not exist!"
    exit 1
  fi
  echo "  OK: $file exists"
done

### Check v4l2loopback was built for the kernel that ships in the image
KERNEL_VERSION=$(rpm -q kernel-core --queryformat "%{VERSION}-%{RELEASE}.%{ARCH}" | tail -n 1)
if ! modinfo -k "$KERNEL_VERSION" v4l2loopback &>/dev/null; then
  echo "ERROR: v4l2loopback module not found for kernel $KERNEL_VERSION!"
  exit 1
fi
echo "  OK: v4l2loopback module present for kernel $KERNEL_VERSION"

### Check signature verification is configured for our images
REGISTRY_PATH="ghcr.io/${IMAGE_VENDOR:-binarypie-dev}"
REGISTRY_PATH="${REGISTRY_PATH,,}"
if ! jq -e --arg repo "$REGISTRY_PATH" \
    '.transports.docker[$repo][0].type == "sigstoreSigned"' /etc/containers/policy.json >/dev/null; then
  echo "ERROR: policy.json has no sigstoreSigned rule for $REGISTRY_PATH!"
  exit 1
fi
if ! cmp -s /etc/pki/containers/hypercube.pub /ctx/cosign.pub; then
  echo "ERROR: /etc/pki/containers/hypercube.pub missing or different from cosign.pub!"
  exit 1
fi
if ! grep -q "use-sigstore-attachments: true" /etc/containers/registries.d/hypercube.yaml; then
  echo "ERROR: registries.d entry for $REGISTRY_PATH missing!"
  exit 1
fi
echo "  OK: signature verification configured for $REGISTRY_PATH"

### Validate the niri config (follows the include into /usr/share/hypercube)
if ! niri validate -c /etc/niri/config.kdl; then
  echo "ERROR: niri config failed validation!"
  exit 1
fi
echo "  OK: niri config is valid"

### Flatpaks must not be baked into /var (they'd never update)
if [ -n "$(flatpak list --system --app --columns=application 2>/dev/null)" ]; then
  echo "ERROR: system flatpaks are installed in the image; list them in preinstall.d instead!"
  exit 1
fi
echo "  OK: no flatpaks baked into the image"

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
  "hypercube-wifi-resume.service"
  "hypercube-flatpak-preinstall.service"
)

for svc in "${REQUIRED_SERVICES[@]}"; do
  if ! systemctl is-enabled "$svc" &>/dev/null; then
    echo "ERROR: Required service '$svc' is not enabled!"
    exit 1
  fi
  echo "  OK: $svc enabled"
done

echo "All Hypercube validation tests passed!"
