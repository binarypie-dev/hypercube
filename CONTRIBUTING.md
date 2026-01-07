# Contributing to Hypercube

This guide covers the repository structure, build system, and how to make changes to Hypercube.

## Repository Structure

```
hypercube/
├── branding/                    # Visual assets
│   ├── hypercube-logo.png       # Main logo (200x200)
│   ├── background.png           # Desktop background
│   └── animation-*.png          # Plymouth boot animation (12 frames)
│
├── build_files/                 # Build scripts
│   ├── shared/
│   │   ├── build.sh             # Main orchestrator
│   │   └── clean-stage.sh       # Post-build cleanup
│   └── hypercube/
│       ├── 00-hypercube-branding.sh    # OS branding & Plymouth
│       ├── 01-hypercube-packages.sh    # Package installation
│       ├── 02-hypercube-theming.sh     # Tokyo Night theme
│       ├── 03-hypercube-configs.sh     # Config file installation
│       └── 99-tests.sh                 # Build validation
│
├── dot_files/                   # User configurations
│   ├── fish/                    # Fish shell config
│   ├── ghostty/                 # Ghostty terminal
│   ├── gitui/                   # Gitui config
│   ├── gtk-3.0/                 # GTK3 settings
│   ├── gtk-4.0/                 # GTK4 settings
│   ├── hypr/                    # Hyprland configs
│   │   ├── hyprland.conf        # Main compositor config
│   │   ├── hyprlock.conf        # Lock screen
│   │   ├── hypridle.conf        # Idle management
│   │   └── hyprpaper.conf       # Wallpaper
│   ├── lazygit/                 # Lazygit config
│   ├── nvim/                    # Neovim/LazyVim setup
│   ├── qt6ct/                   # Qt6 theming
│   ├── quickshell/              # App launcher
│   └── starship/                # Shell prompt
│
├── system_files/                # System-level files
│   └── shared/
│       ├── usr/
│       │   ├── share/
│       │   │   ├── plymouth/themes/hypercube/  # Boot theme
│       │   │   └── pixmaps/                    # System logos
│       │   └── lib/
│       │       ├── bootc/kargs.d/              # Kernel arguments
│       │       └── environment.d/              # Environment variables
│       └── etc/
│           └── dconf/                          # System dconf settings
│
├── .github/workflows/           # CI/CD
│   ├── build.yml                # Container build & publish
│   └── build-disk.yml           # ISO/disk image generation
│
├── Containerfile                # Container build definition
├── Justfile                     # Development commands
└── cosign.pub                   # Image signing key
```

## Build System

### How It Works

1. **Containerfile** defines a multi-stage build:
   - Stage 1 (`ctx`): Aggregates build context from `system_files/` and `build_files/`
   - Stage 2: Builds on `bluefin-dx:stable-daily` base image

2. **build.sh** orchestrates the build:
   - Copies `system_files/` to root filesystem via rsync
   - Runs numbered scripts in `build_files/hypercube/` sequentially
   - Scripts are named `00-*.sh` through `99-*.sh` for ordering

3. **dot_files/** are copied to `/usr/share/hypercube/config/` and made available via XDG paths

### Build Script Execution Order

| Script | Purpose |
|--------|---------|
| `00-hypercube-branding.sh` | OS release info, Plymouth theme, GDM dconf |
| `01-hypercube-packages.sh` | Package installation via DNF/COPR |
| `02-hypercube-theming.sh` | Tokyo Night GTK/icon theme installation |
| `03-hypercube-configs.sh` | Config file deployment (fish, gtk, etc.) |
| `99-tests.sh` | Validation tests for required packages/files |

### Configuration Deployment

Configurations follow the XDG Base Directory specification:

- **System defaults**: `/usr/share/hypercube/config/`
- **User overrides**: `~/.config/`

The environment file at `/usr/lib/environment.d/60-hypercube-xdg.conf` adds Hypercube's config directory to `XDG_CONFIG_DIRS`.

## Development Commands

Use [just](https://just.systems/) to run development tasks:

### Building

```bash
just build              # Build main variant locally
just build nvidia       # Build NVIDIA variant
just build-all          # Build both variants
just build-ghcr         # Build for GHCR (rootful)
```

### Testing

```bash
just run                # Run container interactively
just run nvidia         # Run NVIDIA variant
```

### ISO Generation

```bash
just build-iso          # Build ISO from local image
just build-iso nvidia   # Build NVIDIA ISO
just build-iso-ghcr     # Build ISO from GHCR image
just run-iso <file>     # Test ISO in QEMU VM
```

### Maintenance

```bash
just clean              # Remove build artifacts
just lint               # Check shell scripts (shellcheck)
just format             # Format shell scripts (shfmt)
just check              # Validate Justfile syntax
just fix                # Fix Justfile formatting
```

### Verification

```bash
just verify-container hypercube latest    # Verify image signature
```

## Making Changes

### Adding Packages

Edit `build_files/hypercube/01-hypercube-packages.sh`:

```bash
# From Fedora repos
dnf5 -y install package-name

# From COPR
dnf5 -y copr enable owner/repo
dnf5 -y install package-name
```

Add to test validation in `99-tests.sh`:

```bash
REQUIRED_PACKAGES=(
    # ...
    "package-name"
)
```

### Modifying Configurations

1. Edit files in `dot_files/` for user configs
2. Edit files in `system_files/` for system configs
3. Configs are automatically deployed during build

### Adding System Files

Place files in `system_files/shared/` mirroring the target path:

```
system_files/shared/usr/share/foo/bar.conf
→ Deployed to /usr/share/foo/bar.conf
```

### Testing Locally

```bash
# Build the image
just build

# Run interactively to test
just run

# Or build and test ISO
just build-iso
just run-iso hypercube.iso
```

## Forking Hypercube

To create your own variant:

1. **Fork** the repository on GitHub

2. **Update branding**:
   - Edit `build_files/hypercube/00-hypercube-branding.sh`
   - Replace images in `branding/`
   - Update `artifacthub-repo.yml`

3. **Customize packages** in `01-hypercube-packages.sh`

4. **Modify configs** in `dot_files/` and `system_files/`

5. **Enable GitHub Actions**:
   - Go to Settings → Actions → General
   - Enable "Read and write permissions"
   - The workflow will build and publish to your GHCR

6. **Your image** will be available at:
   ```
   ghcr.io/<your-username>/<your-repo>:latest
   ```

## Code Style

- Shell scripts: Follow [shellcheck](https://www.shellcheck.net/) recommendations
- Use `shfmt` for consistent formatting
- Keep scripts focused and well-commented
- Test changes locally before pushing

## Pull Requests

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally with `just build && just run`
5. Run `just lint` to check for issues
6. Submit a pull request

## Questions?

- [Open an issue](https://github.com/binarypie-dev/hypercube/issues) for bugs or features
- [Universal Blue Discord](https://discord.gg/WEu6BdFEtp) for community help
