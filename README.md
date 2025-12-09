# Hypercube

A cloud-native NixOS workstation with Hyprland, opinionated TUI tools, and vim keybindings everywhere.

## Features

- **Hyprland** - Dynamic tiling Wayland compositor with Tokyo Night theme
- **Fish shell** - Modern shell with vim keybindings and hydro prompt
- **Neovim** - LazyVim configuration with full LSP support
- **Cloud-native tools** - k9s, kubectl, helm, terraform, lazydocker, and more
- **Modern CLI** - eza, bat, ripgrep, fzf, zoxide, atuin
- **Vim mode everywhere** - Shell, TUIs, pagers, and compositor all use vim keybindings

## Quick Start

### Option 1: From ISO

Download the latest ISO from [Releases](https://github.com/binarypie-dev/hypercube/releases) and boot it.

```bash
# Login: nixos / nixos
# Run the Calamares installer from the app menu
```

After installation, apply the full configuration:

```bash
sudo nixos-rebuild switch --flake github:binarypie-dev/hypercube#hypercube
```

### Option 2: From Existing NixOS

```bash
# Clone the repo
git clone https://github.com/binarypie-dev/hypercube.git
cd hypercube

# Generate hardware config
sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix

# Apply configuration
sudo nixos-rebuild switch --flake .#hypercube
```

### Option 3: Fresh Install

Boot from a NixOS ISO, then:

```bash
# Partition disks (example for UEFI with btrfs)
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MB 512MB
parted /dev/nvme0n1 -- set 1 esp on
parted /dev/nvme0n1 -- mkpart primary 512MB 100%

mkfs.fat -F 32 -n boot /dev/nvme0n1p1
mkfs.btrfs -L nixos /dev/nvme0n1p2

mount /dev/nvme0n1p2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

mount -o subvol=@,compress=zstd,noatime /dev/nvme0n1p2 /mnt
mkdir -p /mnt/{home,boot}
mount -o subvol=@home,compress=zstd,noatime /dev/nvme0n1p2 /mnt/home
mount /dev/nvme0n1p1 /mnt/boot

# Generate hardware config
nixos-generate-config --root /mnt

# Install
nixos-install --flake github:binarypie-dev/hypercube#hypercube

# Reboot
reboot
```

## Configuration

### Customize Username/Hostname

Edit `flake.nix`:

```nix
username = "yourusername";
hostname = "yourhostname";
```

### Customize Git

Edit `home/git.nix`:

```nix
userName = "Your Name";
userEmail = "your@email.com";
```

### Customize Timezone

Edit `configuration.nix`:

```nix
time.timeZone = "America/Los_Angeles";
```

## Directory Structure

```text
.
├── flake.nix              # Flake definition with inputs
├── configuration.nix      # System-level NixOS configuration
├── home.nix               # Home Manager entry point
├── iso.nix                # ISO image configuration
├── Justfile               # Build recipes
└── home/
    ├── packages.nix       # All user packages
    ├── fish.nix           # Fish shell + aliases
    ├── neovim.nix         # Neovim + LSPs
    ├── git.nix            # Git configuration
    ├── hyprland.nix       # Hyprland compositor
    ├── waybar.nix         # Status bar
    ├── ...                # Other program configs
    └── nvim/              # Neovim LazyVim config
```

## Keybindings

### Hyprland

| Key                       | Action                 |
| ------------------------- | ---------------------- |
| `Super + Q`               | Terminal (ghostty)     |
| `Super + C`               | Close window           |
| `Super + R`               | App launcher (wofi)    |
| `Super + F`               | Fullscreen             |
| `Super + V`               | Toggle floating        |
| `Super + H/J/K/L`         | Move focus (vim-style) |
| `Super + Shift + H/J/K/L` | Move window            |
| `Super + Ctrl + H/J/K/L`  | Resize window          |
| `Super + 1-0`             | Switch workspace       |
| `Super + Shift + 1-0`     | Move to workspace      |
| `Super + Shift + L`       | Lock screen            |

### Shell Aliases

| Alias | Command    |
| ----- | ---------- |
| `k`   | kubectl    |
| `kx`  | kubectx    |
| `kn`  | kubens     |
| `lg`  | lazygit    |
| `ld`  | lazydocker |
| `tf`  | terraform  |

## Included Tools

### Kubernetes

- kubectl, kubectx, k9s, helm, stern, kustomize, argocd, fluxcd

### Containers

- lazydocker, dive, ctop, skopeo, buildah

### Infrastructure

- terraform, opentofu

### Cloud CLIs

- awscli2, google-cloud-sdk, azure-cli

### Modern CLI

- eza, bat, delta, zoxide, fzf, atuin, ripgrep, fd, jq, yq

## Development

```bash
# Enter dev shell with nix tools
just dev

# Format nix files
just fmt

# Lint nix files
just lint

# Run all checks
just check-all

# Build ISO
just build-iso

# Test ISO in VM
just run-iso
```

## Building

### Build System Configuration

```bash
just build
```

### Build ISO

```bash
just build-iso
# ISO output: result-iso/iso/hypercube-*.iso
```

### Test in VM

```bash
just run-iso
```

## Customization

### Adding Packages

User packages go in `home/packages.nix`:

```nix
home.packages = with pkgs; [
  your-package
];
```

System packages go in `configuration.nix`:

```nix
environment.systemPackages = with pkgs; [
  your-package
];
```

### Changing Theme

Tokyo Night is used throughout. Key files to modify:

- `home/hyprland.nix` - Compositor colors
- `home/waybar.nix` - Status bar styles
- `home/wofi.nix` - Launcher styles
- `home/k9s.nix` - Kubernetes TUI theme

### Switching Prompt

Starship is included but disabled. To use instead of hydro, edit `home/starship.nix`:

```nix
programs.starship.enable = true;
```

## Standalone Home Manager

Use the configuration on non-NixOS systems (Fedora, Ubuntu, etc.):

```bash
# Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Apply home-manager config
nix run home-manager -- switch --flake github:binarypie-dev/hypercube#binarypie
```

## License

See [LICENSE](LICENSE)
