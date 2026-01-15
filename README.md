# Hypercube

> Cloud-native development environment with vim keybindings

[![Build](https://github.com/binarypie-dev/hypercube/actions/workflows/build.yml/badge.svg)](https://github.com/binarypie-dev/hypercube/actions/workflows/build.yml)
[![nvim-dev](https://github.com/binarypie-dev/hypercube/actions/workflows/build-nvim-dev.yml/badge.svg)](https://github.com/binarypie-dev/hypercube/actions/workflows/build-nvim-dev.yml)
[![Copr](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/datacube/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/)
[![GHCR](https://img.shields.io/badge/GHCR-ghcr.io%2Fbinarypie--dev%2Fhypercube-blue)](https://ghcr.io/binarypie-dev/hypercube)

<details>
<summary><strong>COPR Package Build Status</strong></summary>

#### Hyprland Core Libraries
| Package | Status |
|---------|--------|
| hyprutils | [![hyprutils](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprutils/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprutils/) |
| hyprlang | [![hyprlang](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprlang/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprlang/) |
| hyprwayland-scanner | [![hyprwayland-scanner](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprwayland-scanner/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprwayland-scanner/) |
| hyprgraphics | [![hyprgraphics](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprgraphics/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprgraphics/) |
| hyprcursor | [![hyprcursor](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprcursor/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprcursor/) |
| hyprland-protocols | [![hyprland-protocols](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprland-protocols/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprland-protocols/) |
| hyprwire | [![hyprwire](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprwire/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprwire/) |
| aquamarine | [![aquamarine](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/aquamarine/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/aquamarine/) |
| hyprland-qt-support | [![hyprland-qt-support](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprland-qt-support/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprland-qt-support/) |
| glaze | [![glaze](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/glaze/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/glaze/) |

#### Hyprland Compositor & Tools
| Package | Status |
|---------|--------|
| hyprland | [![hyprland](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprland/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprland/) |
| hyprlock | [![hyprlock](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprlock/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprlock/) |
| hypridle | [![hypridle](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hypridle/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hypridle/) |
| hyprpaper | [![hyprpaper](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprpaper/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprpaper/) |
| xdg-desktop-portal-hyprland | [![xdg-desktop-portal-hyprland](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/xdg-desktop-portal-hyprland/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/xdg-desktop-portal-hyprland/) |
| hyprpolkitagent | [![hyprpolkitagent](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprpolkitagent/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprpolkitagent/) |
| hyprtoolkit | [![hyprtoolkit](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprtoolkit/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprtoolkit/) |
| hyprland-guiutils | [![hyprland-guiutils](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprland-guiutils/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/hyprland-guiutils/) |
| uwsm | [![uwsm](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/uwsm/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/uwsm/) |

#### CLI Tools
| Package | Status |
|---------|--------|
| eza | [![eza](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/eza/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/eza/) |
| starship | [![starship](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/starship/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/starship/) |
| lazygit | [![lazygit](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/lazygit/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/lazygit/) |
| wifitui | [![wifitui](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/wifitui/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/wifitui/) |

#### Other
| Package | Status |
|---------|--------|
| quickshell | [![quickshell](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/quickshell/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/quickshell/) |
| regreet | [![regreet](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/regreet/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/regreet/) |
| livesys-scripts | [![livesys-scripts](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/livesys-scripts/status_image/last_build.png)](https://copr.fedorainfracloud.org/coprs/binarypie/hypercube/package/livesys-scripts/) |

</details>

Hypercube is an opinionated, ready-to-use development environment built on [Universal Blue's base-main](https://github.com/ublue-os/main) image with Fedora 43. It provides a complete Hyprland-based workflow with consistent vim keybindings across all tools and Tokyo Night theming throughout.

## Features

### Keyboard-First Workflow

Every tool is configured with vim keybindings out of the box:

- **Fish shell** with vi mode enabled
- **Hyprland** window management via `hjkl` keys
- **Ghostty terminal** with vim-style pane navigation
- **Neovim** with LazyVim as the primary editor

### Desktop Environment

- **Hyprland** - Dynamic tiling Wayland compositor for keyboard-driven efficiency
- **Quickshell** - Custom shell with notifications, app launcher, and system controls

### Development Tools

Pre-configured and ready to use:

- **Neovim** (nightly) with LazyVim, LSP, and language support
- **Lazygit** for interactive Git operations
- **Fish** shell with Starship prompt
- **Ghostty** GPU-accelerated terminal
- **Distrobox** and **Podman** for containerized development environments

### Consistent Theming

Tokyo Night color scheme everywhere:

- GTK and Qt applications
- Terminal emulators
- Neovim and all CLI tools
- Plymouth boot animation
- ReGreet login screen
- System-wide dark mode enforced

## Screenshots

<!-- TODO: Add screenshots
![Hyprland Desktop](screenshots/desktop.png)
![Neovim Editing](screenshots/neovim.png)
![Terminal with Starship](screenshots/terminal.png)
-->

*Screenshots coming soon*

## Installation

### Prerequisites

- A system running Fedora Atomic (Silverblue, Kinoite, Bazzite, Bluefin, Aurora, etc.)
- Basic familiarity with image-based operating systems

### Switch to Hypercube

From your existing Fedora Atomic system:

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/binarypie-dev/hypercube:43
systemctl reboot
```

After the first reboot, you can switch to signed images for additional security:

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/binarypie-dev/hypercube:43
systemctl reboot
```

NVIDIA drivers are included in the unified image.

### Fresh Install (ISO)

Bootable ISOs are available from the [GitHub Releases](https://github.com/binarypie-dev/hypercube/releases) page or can be built locally with `just build-iso`.

### Switching Back

```bash
rpm-ostree rebase <your-previous-image>
systemctl reboot
```

### Resetting Configuration

Hypercube ships default configurations in `/usr/share/hypercube/config/`. Use the built-in commands to safely reset configs (your existing configs are backed up automatically):

```bash
# List available configs
ujust config-list

# Reset a specific app's config (e.g., hyprland)
ujust config-reset hypr

# Reset all Hypercube configs
ujust config-reset

# See differences between your config and defaults
ujust config-diff hypr

# See all differences
ujust config-diff
```

Backups are saved to `~/.config/hypercube-backup-<timestamp>/`.

## What's Included

### Packages

Built on ublue-os/base-main, Hypercube includes:

| Category | Packages |
|----------|----------|
| Compositor | Hyprland, Hyprlock, Hypridle, Hyprpaper, Hyprshot |
| Shell | Quickshell (notifications, launcher, system controls) |
| Terminals | Ghostty |
| Editor | Neovim (nightly) |
| Git Tools | Lazygit |
| Development | Distrobox, Podman |
| Gaming | Steam |
| Theming | Tokyo Night GTK/Qt themes |
| Drivers | NVIDIA (akmods), v4l2loopback |

### Configurations

All configurations live in `/usr/share/hypercube/config/` and are symlinked to `~/.config/` on first login:

- Fish shell with vim mode and Starship prompt
- Hyprland with vim-style navigation
- Neovim with LazyVim distribution
- Ghostty with Tokyo Night colors
- GTK/Qt theming with dark mode

## Documentation

- **[Keybindings Reference](KEYBINDINGS.md)** - Complete keybinding guide for Hyprland, Ghostty, and more
- **[Contributing Guide](CONTRIBUTING.md)** - Repository structure, build system, and development workflow

## Community & Support

- [Open an issue](https://github.com/binarypie-dev/hypercube/issues) for bugs or feature requests
- [Universal Blue Forums](https://universal-blue.discourse.group/) for general questions
- [Universal Blue Discord](https://discord.gg/WEu6BdFEtp) for community chat

## Acknowledgments

Hypercube is built on excellent open source projects:

- [Universal Blue](https://universal-blue.org/) - Image-based desktop platform
- [Hyprland](https://hyprland.org/) - Wayland compositor
- [Quickshell](https://quickshell.outfoxxed.me/) - Qt6/QML shell toolkit
- [LazyVim](https://www.lazyvim.org/) - Neovim distribution
- [Tokyo Night](https://github.com/folke/tokyonight.nvim) - Color scheme

## License

This project follows Universal Blue licensing. See [LICENSE](LICENSE) for details.
