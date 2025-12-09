# Hypercube NixOS Justfile

[private]
default:
    @just --list

# ============================================================================
# Development
# ============================================================================

# Enter development shell with nix tools
[group('Development')]
dev:
    nix develop

# Format all nix files
[group('Development')]
fmt:
    find . -name "*.nix" -type f -exec nixfmt {} \;

# Check nix file syntax
[group('Development')]
check:
    find . -name "*.nix" -type f -exec nix-instantiate --parse-only {} \;

# Lint nix files with statix
[group('Development')]
lint:
    statix check .

# Fix issues found by statix
[group('Development')]
lint-fix:
    statix fix .

# Run all checks (format check, syntax, lint)
[group('Development')]
check-all: && lint
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Checking nix formatting..."
    find . -name "*.nix" -type f -exec nixfmt --check {} \;
    echo "Checking nix syntax..."
    find . -name "*.nix" -type f -exec nix-instantiate --parse-only {} \;
    echo "Running statix..."
    statix check .
    echo "All checks passed!"

# ============================================================================
# NixOS System
# ============================================================================

# Build NixOS configuration (dry-run)
[group('NixOS')]
build:
    nixos-rebuild build --flake .#hypercube

# Switch to new NixOS configuration
[group('NixOS')]
switch:
    sudo nixos-rebuild switch --flake .#hypercube

# Test NixOS configuration in a VM
[group('NixOS')]
test:
    nixos-rebuild build-vm --flake .#hypercube
    ./result/bin/run-*-vm

# Update flake inputs
[group('NixOS')]
update:
    nix flake update

# Show flake info
[group('NixOS')]
info:
    nix flake show
    nix flake metadata

# ============================================================================
# ISO Building
# ============================================================================

# Build the installable ISO
[group('ISO')]
build-iso:
    nix build .#iso --out-link result-iso
    @echo "ISO built: $(readlink -f result-iso)/iso/*.iso"

# Build ISO and show path
[group('ISO')]
iso: build-iso
    @ls -lh result-iso/iso/*.iso

# ============================================================================
# Virtual Machine Testing
# ============================================================================

# Run ISO in QEMU for testing
[group('VM')]
run-iso: build-iso
    #!/usr/bin/env bash
    set -euo pipefail
    ISO=$(find result-iso -name "*.iso" -type f | head -1)
    echo "Running ISO: $ISO"
    qemu-system-x86_64 \
        -enable-kvm \
        -m 4G \
        -smp 2 \
        -cdrom "$ISO" \
        -boot d \
        -cpu host \
        -device virtio-vga-gl \
        -display gtk,gl=on

# Run ISO with more resources
[group('VM')]
run-iso-full: build-iso
    #!/usr/bin/env bash
    set -euo pipefail
    ISO=$(find result-iso -name "*.iso" -type f | head -1)
    echo "Running ISO: $ISO"
    qemu-system-x86_64 \
        -enable-kvm \
        -m 8G \
        -smp 4 \
        -cdrom "$ISO" \
        -boot d \
        -cpu host \
        -device virtio-vga-gl \
        -display gtk,gl=on \
        -drive file=/tmp/hypercube-test.qcow2,format=qcow2,if=virtio,cache=writeback \
        -nic user,model=virtio-net-pci

# Create a test disk for VM installation
[group('VM')]
create-test-disk size="20G":
    qemu-img create -f qcow2 /tmp/hypercube-test.qcow2 {{ size }}

# ============================================================================
# Home Manager (Standalone)
# ============================================================================

# Build home-manager configuration
[group('Home Manager')]
hm-build:
    nix build .#homeConfigurations.binarypie.activationPackage

# Switch home-manager configuration (for non-NixOS)
[group('Home Manager')]
hm-switch:
    nix run home-manager -- switch --flake .#binarypie

# ============================================================================
# Utility
# ============================================================================

# Clean build artifacts
[group('Utility')]
clean:
    rm -rf result result-*
    rm -rf .direnv

# Garbage collect nix store
[group('Utility')]
gc:
    nix-collect-garbage -d

# Show disk usage of nix store
[group('Utility')]
du:
    nix path-info -Sh /run/current-system

# List generations
[group('Utility')]
generations:
    sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
