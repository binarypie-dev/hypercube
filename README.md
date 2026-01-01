# Hypercube (archive)

> Cloud-native development environment with vim keybindings

[![Build](https://github.com/binarypie-dev/hypercube/actions/workflows/build.yml/badge.svg)](https://github.com/binarypie-dev/hypercube/actions/workflows/build.yml)
[![GHCR](https://img.shields.io/badge/GHCR-ghcr.io%2Fbinarypie--dev%2Fhypercube-blue)](https://ghcr.io/binarypie-dev/hypercube)

Hypercube is an opinionated, ready-to-use development environment built on [Bluefin-DX](https://projectbluefin.io/). It provides a complete cloud-native workflow with consistent vim keybindings across all tools, beautiful Tokyo Night theming, and your choice of desktop environment.

## Features

### Vim-First Workflow

Every tool is configured with vim keybindings out of the box:

- **Fish shell** with vi mode enabled
- **Hyprland** window management via `hjkl` keys
- **Ghostty terminal** with vim-style pane navigation
- **Neovim** with LazyVim as the primary editor

### Desktop Environments

Choose your preferred workflow:

- **Hyprland** - Dynamic tiling Wayland compositor for keyboard-driven efficiency
- **GNOME** - Traditional desktop experience (inherited from Bluefin)

### Development Tools

Pre-configured and ready to use:

- **Neovim** (nightly) with LazyVim, LSP, and language support
- **Lazygit** for interactive Git operations
- **Fish** shell with Starship prompt
- **Ghostty** & **WezTerm** GPU-accelerated terminals
- **Quickshell** application launcher and system controls

### Consistent Theming

Tokyo Night color scheme everywhere:

- GTK and Qt applications
- Terminal emulators
- Neovim and all CLI tools
- Plymouth boot animation
- GDM login screen
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

- A system running a bootc-compatible image (Bazzite, Bluefin, Aurora, or Fedora Atomic)
- Basic familiarity with container-based operating systems

### Switch to Hypercube

From your existing bootc system:

**Intel/AMD Graphics:**
```bash
sudo bootc switch ghcr.io/binarypie-dev/hypercube:latest
systemctl reboot
```

**NVIDIA Graphics:**
```bash
sudo bootc switch ghcr.io/binarypie-dev/hypercube:latest-nvidia
systemctl reboot
```

### Fresh Install (ISO)

Bootable ISOs are available from the [GitHub Releases](https://github.com/binarypie-dev/hypercube/releases) page or can be built locally with `just build-iso`.

### Switching Back

```bash
sudo bootc switch <your-previous-image>
systemctl reboot
```

## What's Included

### Packages

On top of Bluefin-DX, Hypercube adds:

| Category | Packages |
|----------|----------|
| Compositor | Hyprland, Hyprlock, Hypridle, Hyprpaper, Hyprshot |
| Terminals | Ghostty, WezTerm |
| Editor | Neovim (nightly) |
| Git Tools | Lazygit |
| Launcher | Quickshell |
| Theming | Tokyo Night GTK/Qt themes |

### Configurations

All configurations live in `/usr/share/hypercube/config/` and can be overridden in `~/.config/`:

- Fish shell with vim mode and Starship prompt
- Hyprland with vim-style navigation
- Neovim with LazyVim distribution
- Ghostty and WezTerm with Tokyo Night colors
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
- [Project Bluefin](https://projectbluefin.io/) - Developer experience foundation
- [Hyprland](https://hyprland.org/) - Wayland compositor
- [LazyVim](https://www.lazyvim.org/) - Neovim distribution
- [Tokyo Night](https://github.com/folke/tokyonight.nvim) - Color scheme

## License

This project follows Universal Blue licensing. See [LICENSE](LICENSE) for details.
