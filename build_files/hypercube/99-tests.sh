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
  # Desktop (niri session)
  "niri"
  "xwayland-satellite"
  "xdg-desktop-portal-gnome"
  "quickshell"
  "swaybg"
  "swaylock"
  "swayidle"
  # Passwords: polkit agent (admin prompts, e.g. unlocking LUKS drives) and
  # the PAM module that unlocks GNOME Keyring at login
  "mate-polkit"
  "gnome-keyring"
  "gnome-keyring-pam"
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
  "/etc/swaylock/config"
  "/etc/swayidle/config"
  "/usr/lib/systemd/user/hypercube-polkit-agent.service"
  "/usr/libexec/polkit-mate-authentication-agent-1"
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
)

for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -e "$file" ]; then
    echo "ERROR: Required file '$file' does not exist!"
    exit 1
  fi
  echo "  OK: $file exists"
done

### Validate the niri config (follows the include into /usr/share/hypercube)
if ! niri validate -c /etc/niri/config.kdl; then
  echo "ERROR: niri config failed validation!"
  exit 1
fi
echo "  OK: niri config is valid"

### Polkit agent must start with the graphical session, or nothing can ask
### for the admin password
if ! systemctl --global is-enabled hypercube-polkit-agent.service &>/dev/null; then
  echo "ERROR: hypercube-polkit-agent.service is not enabled for user sessions!"
  exit 1
fi
echo "  OK: hypercube-polkit-agent.service enabled for user sessions"

### greetd's PAM stack must load pam_gnome_keyring so login unlocks the
### keyring. Fedora's greetd PAM file lists it as optional ("-auth"), which is
### silently skipped unless the module itself is installed, so check both.
if ! grep -qs 'pam_gnome_keyring' /etc/pam.d/greetd /usr/lib/pam.d/greetd; then
  echo "ERROR: greetd PAM stack does not include pam_gnome_keyring!"
  exit 1
fi
if [ ! -e /usr/lib64/security/pam_gnome_keyring.so ]; then
  echo "ERROR: pam_gnome_keyring.so is not installed!"
  exit 1
fi
echo "  OK: greetd PAM stack unlocks GNOME Keyring"

### Hyprland is gone; make sure nothing pulled it back in
for pkg in hyprland hyprlock hypridle hyprpolkitagent uwsm; do
  if rpm -q "$pkg" &>/dev/null; then
    echo "ERROR: '$pkg' should not be installed!"
    exit 1
  fi
done
echo "  OK: no Hyprland packages installed"

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
)

for svc in "${REQUIRED_SERVICES[@]}"; do
  if ! systemctl is-enabled "$svc" &>/dev/null; then
    echo "ERROR: Required service '$svc' is not enabled!"
    exit 1
  fi
  echo "  OK: $svc enabled"
done

echo "All Hypercube validation tests passed!"
