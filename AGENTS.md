# AGENTS.md

This file provides guidance to coding agents when working with code in this repository.

## Project Overview

Hypercube is a container-based Linux distribution built on Fedora Atomic (via Universal Blue's `base-main:43`). It's a keyboard-first Hyprland desktop with vim keybindings, Tokyo Night theming, and developer tooling. The image is built as an OCI container and deployed via bootc.

## Build Commands

```bash
just build              # Build container image locally (rootless Podman)
just build-force        # Build without cache
just build-ghcr         # Build for GHCR push (rootful)
just run                # Run container interactively for testing
just lint               # Shellcheck all .sh files
just format             # Format all .sh files with shfmt
just check              # Validate Justfile syntax
just fix                # Fix Justfile formatting
```

### VM/ISO Testing

```bash
just build-qcow2-fast   # Create disk image via bootc install
just run-qcow2           # Test qcow2 in VM with virt-manager
just build-iso-local     # Build ISO from local image
just run-iso <file>      # Test ISO in QEMU VM
```

### Package Version Scripts

```bash
./scripts/packages/check-upstream-versions.sh   # Detect upstream updates
./scripts/packages/check-copr-versions.sh       # Compare spec vs COPR builds
./scripts/packages/test-all.sh                  # Run package script tests
```

## Architecture

### Build Pipeline

The `Containerfile` defines a multi-stage build:

1. **Stage `ctx`**: Aggregates `system_files/` and `build_files/` into `/ctx`
2. **Main stage**: Builds from `ghcr.io/ublue-os/base-main:43`, mounts `dot_files/` at `/dot_files`, runs `build.sh`

`build_files/shared/build.sh` orchestrates the build:

- Rsyncs `system_files/shared/` to the root filesystem
- Executes numbered scripts (`00-*.sh` through `99-*.sh`) sequentially from each phase directory

### Build Phases (in order)

| Directory                | Purpose                                               |
| ------------------------ | ----------------------------------------------------- |
| `build_files/base/`      | Kernel, greetd, audio, networking, portals            |
| `build_files/hyprland/`  | Compositor, shell, terminal, editor, CLI tools        |
| `build_files/dx/`        | Language servers, containers (Distrobox/Podman)       |
| `build_files/apps/`      | Applications (Steam, etc.)                            |
| `build_files/hypercube/` | Branding, packages, theming, config deployment, tests |

### Configuration System

Configs follow XDG Base Directory specification:

- `dot_files/` → deployed to `/usr/share/hypercube/config/` (system defaults)
- `/usr/lib/environment.d/60-hypercube-xdg.conf` adds this path to `XDG_CONFIG_DIRS`
- Users override via `~/.config/`
- Fish shell configs go to `/etc/fish/` (Fish doesn't use XDG_CONFIG_DIRS)
- System-level files in `system_files/shared/` mirror the target filesystem path (e.g., `system_files/shared/etc/greetd/config.toml` → `/etc/greetd/config.toml`)

### Build Validation

`build_files/hypercube/99-tests.sh` validates the build by checking:

- Required packages are installed (greetd, hyprland, ghostty, neovim, etc.)
- Required files exist (branding, configs, themes, plymouth)
- os-release contains `ID=hypercube`
- Required services are enabled (greetd, NetworkManager)

Failures exit with code 1, preventing the image from being published.

### COPR Packages

26 custom packages are maintained in `packages/` with RPM spec files. Package metadata, dependencies, and build ordering are defined in `scripts/packages/config.sh`. Packages are built in 5 dependency-ordered batches.

## Shell Script Conventions

- All build scripts use `set -ouex pipefail`
- Scripts are named with numeric prefixes for execution ordering
- Package installation uses `dnf5 -y install`
- COPR repos are enabled with `dnf5 -y copr enable owner/repo`

## Key Integration Points

- **Titanoboa** (`_titanoboa/`): External ISO builder, cloned on demand by `just build-iso-*`
- **Cosign** (`cosign.pub`): Image signature verification
- **GitHub Actions** (`.github/workflows/build.yml`): Builds on PR and daily, pushes to GHCR on merge to main
