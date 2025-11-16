# Hypercube

Hypercube is a custom [bootc](https://github.com/bootc-dev/bootc) image built on top of [Bluefin-DX](https://projectbluefin.io/) with Hyprland and an opinionated set of development tools. This image is designed primarily for my personal software development workflow, but you're welcome to use it, fork it, or submit issues and pull requests.

## What's Inside

Hypercube builds on Bluefin-DX's excellent developer experience foundation and adds:

- **Hyprland**: A dynamic tiling Wayland compositor for an efficient, keyboard-driven workflow
- **Opinionated Development Tools**: A curated set of tools and configurations optimized for my development workflow
- **Personal Preferences**: Custom configurations and tweaks that I've found useful over time

### Available Variants

Hypercube is available in two variants:

- **Regular**: Built on `bluefin-dx:stable-daily` for systems with Intel/AMD graphics
- **NVIDIA**: Built on `bluefin-dx-nvidia:stable-daily` with NVIDIA driver support

This is not meant to be a general-purpose distribution, but rather a personal daily driver that happens to be publicly available for others who might share similar preferences.

## Community & Support

While this is a personal image, community contributions are welcome! If you encounter issues or have suggestions:

- [Open an issue](../../issues) on this repository
- Submit a pull request with improvements
- For general bootc and Universal Blue questions:
  - [Universal Blue Forums](https://universal-blue.discourse.group/)
  - [Universal Blue Discord](https://discord.gg/WEu6BdFEtp)
  - [bootc discussion forums](https://github.com/bootc-dev/bootc/discussions)

## Installation

### Prerequisites

- A machine running a bootc-compatible image (e.g., Bazzite, Bluefin, Aurora, or Fedora Atomic)
- Basic familiarity with bootc and container-based operating systems

### Switching to Hypercube

From your existing bootc system, run:

**For systems with Intel/AMD graphics:**
```bash
sudo bootc switch ghcr.io/binarypie-dev/hypercube:latest
```

**For systems with NVIDIA graphics:**
```bash
sudo bootc switch ghcr.io/binarypie-dev/hypercube:latest-nvidia
```

Then reboot your system:

```bash
systemctl reboot
```

After rebooting, you'll be running Hypercube.

### Switching Back

If Hypercube isn't for you, you can switch back to your previous image:

```bash
sudo bootc status  # Find your previous image
sudo bootc switch <your-previous-image>
systemctl reboot
```

## Customization & Forking

Want to create your own variant of Hypercube? You're welcome to fork this repository! Here's how the build system works:

### Repository Structure

- **[Containerfile](./Containerfile)**: The main build definition. This is where the base image is selected and the build process is orchestrated.
- **[build.sh](./build_files/build.sh)**: The primary customization script. This is where packages are installed and system configurations are applied.
- **[build.yml](./.github/workflows/build.yml)**: GitHub Actions workflow that builds and publishes the image to GitHub Container Registry (GHCR).

### Building Your Own Variant

If you fork this repository:

1. Modify `build.sh` to add/remove packages and configurations
2. Update the `Containerfile` if you want to change the base image
3. Push your changes - GitHub Actions will automatically build your image
4. Your image will be available at `ghcr.io/<your-username>/<your-repo-name>`

For detailed information about customizing the image, see the files mentioned above. They contain examples and documentation.

## Building Disk Images

The repository includes workflows for creating bootable disk images (ISO, QCOW2, raw) using [bootc-image-builder](https://osbuild.org/docs/bootc/). These can be used for:

- Installing Hypercube on bare metal (ISO)
- Testing in virtual machines (QCOW2)
- Deploying to cloud environments (raw)

### Available via GitHub Actions

The [build-disk.yml](./.github/workflows/build-disk.yml) workflow can generate these images automatically. After the workflow completes, disk images are available as artifacts in the GitHub Actions run.

### Building Locally

You can also build disk images locally using the included `just` commands (see [Justfile Documentation](#justfile-documentation) below).

## Artifacthub

Hypercube is indexed on [artifacthub.io](https://artifacthub.io) to make it easier to discover and track. If you fork this image, you can list your own variant there as well using the `artifacthub-repo.yml` file.

Learn more in the [Universal Blue Artifacthub discussion](https://universal-blue.discourse.group/t/listing-your-custom-image-on-artifacthub/6446).

## Development with Just

The repository includes a [`Justfile`](./Justfile) with commands for building and testing Hypercube locally. [just](https://just.systems/) is a command runner that simplifies common development tasks.

Just is pre-installed on all Universal Blue images (including Hypercube and Bluefin-DX). If you're using another system, install it from your package manager or see the [just installation guide](https://just.systems/man/en/introduction.html).

### Available Commands

Run `just` without arguments to see all available commands. Here are the most useful ones:

#### Building

- `just build` - Build the Hypercube container image locally (regular variant)
- `just build-regular` - Build the regular variant (Intel/AMD graphics)
- `just build-nvidia` - Build the NVIDIA variant
- `just build-all` - Build both regular and NVIDIA variants
- `just build-iso` - Build a bootable ISO image
- `just build-qcow2` - Build a QCOW2 VM image
- `just build-raw` - Build a raw disk image

#### Testing

- `just run-vm-qcow2` - Run Hypercube in a VM using QCOW2 image
- `just spawn-vm` - Run Hypercube using systemd-vmspawn

#### Maintenance

- `just clean` - Clean build artifacts
- `just lint` - Check shell scripts for issues
- `just format` - Format shell scripts

For detailed usage and additional commands, see the [Justfile](./Justfile) itself.

## Related Projects

Hypercube is part of the larger Universal Blue ecosystem. Check out these other custom images for inspiration:

- [Bluefin-DX](https://projectbluefin.io/) - The base image for Hypercube
- [m2Giles' OS](https://github.com/m2giles/m2os) - Another custom bootc image
- [bOS](https://github.com/bsherman/bos) - Custom image by bsherman
- [Homer](https://github.com/bketelsen/homer/) - Custom image by bketelsen
- [Amy OS](https://github.com/astrovm/amyos) - Custom image by astrovm
- [VeneOS](https://github.com/Venefilyn/veneos) - Custom image by Venefilyn

## License

This project follows the same licensing as the Universal Blue project. See the LICENSE file for details.

## Acknowledgments

Hypercube is built on the shoulders of giants:

- [Universal Blue](https://universal-blue.org/) for the excellent image-based desktop platform
- [Project Bluefin](https://projectbluefin.io/) for the outstanding developer experience foundation
- [bootc](https://github.com/bootc-dev/bootc) for the bootable container technology
- [Hyprland](https://hyprland.org/) for the amazing Wayland compositor
- The Fedora and broader open source community
