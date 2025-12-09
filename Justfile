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
# Docker Testing
# ============================================================================

# Build the Docker image for testing
[group('Docker')]
docker-build:
    docker build -t hypercube-nix .

# Create persistent volume for Nix store cache
[group('Docker')]
docker-cache:
    docker volume create hypercube-nix-store 2>/dev/null || true

# Run nix flake show in Docker
[group('Docker')]
docker-show: docker-build docker-cache
    docker run --rm -v hypercube-nix-store:/nix hypercube-nix nix flake show

# Run nix flake check in Docker
[group('Docker')]
docker-check: docker-build docker-cache
    docker run --rm -v hypercube-nix-store:/nix hypercube-nix nix flake check --no-build

# Build ISO in Docker with persistent cache (outputs to ./result-iso)
[group('Docker')]
docker-iso: docker-build docker-cache
    rm -rf result-iso
    mkdir -p result-iso
    docker run --rm \
        -e OWNER_UID=$(id -u) \
        -e OWNER_GID=$(id -g) \
        -v hypercube-nix-store:/nix \
        -v $(pwd)/result-iso:/workspace/result-iso \
        hypercube-nix sh -c "nix build .#iso && cp -rL result/* result-iso/ && chown -R \$OWNER_UID:\$OWNER_GID result-iso/"

# Run interactive shell in Docker for debugging
[group('Docker')]
docker-shell: docker-build docker-cache
    docker run --rm -it \
        -v hypercube-nix-store:/nix \
        -v $(pwd):/workspace \
        hypercube-nix bash

# Test ISO in QEMU (4 CPUs, 8GB RAM, 10GB disk)
[group('Docker')]
docker-test-iso:
    #!/usr/bin/env bash
    set -euo pipefail
    ISO=$(find result-iso -name "*.iso" -type f 2>/dev/null | head -1)
    if [[ -z "$ISO" ]]; then
        echo "No ISO found in result-iso/. Run 'just docker-iso' first."
        exit 1
    fi
    DISK="/tmp/hypercube-test.qcow2"
    if [[ ! -f "$DISK" ]]; then
        echo "Creating 10GB test disk at $DISK"
        qemu-img create -f qcow2 "$DISK" 10G
    fi
    echo "Running ISO: $ISO"
    qemu-system-x86_64 \
        -enable-kvm \
        -m 8G \
        -smp 4 \
        -cpu host \
        -cdrom "$ISO" \
        -boot d \
        -drive file="$DISK",format=qcow2,if=virtio \
        -device virtio-vga-gl \
        -display gtk,gl=on \
        -nic user,model=virtio-net-pci

# Clean Docker cache volume
[group('Docker')]
docker-clean:
    docker volume rm hypercube-nix-store || true

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
