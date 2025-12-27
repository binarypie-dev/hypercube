# Hypercube Build System

# Configuration
export repo_organization := env("REPO_ORGANIZATION", "binarypie-dev")
export image_name := env("IMAGE_NAME", "hypercube")
export base_image := env("BASE_IMAGE", "ghcr.io/ublue-os/base-main")
export base_image_nvidia := env("BASE_IMAGE_NVIDIA", "ghcr.io/ublue-os/base-nvidia")
export default_tag := env("DEFAULT_TAG", "stable-daily")

# Runtime detection
export SUDO := if `id -u` == "0" { "" } else { "sudo" }
export PODMAN := if path_exists("/usr/bin/podman") == "true" { "/usr/bin/podman" } else { "podman" }

[private]
default:
    @just --list

# ============================================
# Build Recipes
# ============================================

# Build container image
[group('Build')]
build flavor="main" ghcr="0":
    #!/usr/bin/env bash
    set -euo pipefail

    # Determine base image based on flavor
    if [[ "{{ flavor }}" == "nvidia" ]]; then
        BASE="{{ base_image_nvidia }}:{{ default_tag }}"
        TAG="{{ default_tag }}-nvidia"
    else
        BASE="{{ base_image }}:{{ default_tag }}"
        TAG="{{ default_tag }}"
    fi

    IMAGE_FULL="{{ image_name }}:${TAG}"

    echo "========================================"
    echo "Building: ${IMAGE_FULL}"
    echo "Base:     ${BASE}"
    echo "========================================"

    BUILD_ARGS=()
    BUILD_ARGS+=("--build-arg" "BASE_IMAGE=${BASE}")
    BUILD_ARGS+=("--build-arg" "IMAGE_NAME={{ image_name }}")
    BUILD_ARGS+=("--build-arg" "IMAGE_VENDOR={{ repo_organization }}")

    if [[ -z "$(git status -s)" ]]; then
        BUILD_ARGS+=("--build-arg" "SHA_HEAD_SHORT=$(git rev-parse --short HEAD)")
    fi

    # Use rootful podman for GHCR builds
    if [[ "{{ ghcr }}" == "1" ]]; then
        {{ SUDO }} {{ PODMAN }} build \
            "${BUILD_ARGS[@]}" \
            --pull=newer \
            --tag "${IMAGE_FULL}" \
            .
    else
        {{ PODMAN }} build \
            "${BUILD_ARGS[@]}" \
            --pull=newer \
            --tag "${IMAGE_FULL}" \
            .
    fi

    echo ""
    echo "========================================"
    echo "Build complete: ${IMAGE_FULL}"
    echo "========================================"

# Build for GHCR push (rootful)
[group('Build')]
build-ghcr flavor="main":
    @just build {{ flavor }} 1

# Build both flavors
[group('Build')]
build-all:
    @echo "Building main flavor..."
    @just build main
    @echo ""
    @echo "Building nvidia flavor..."
    @just build nvidia

# Run container interactively for testing
[group('Build')]
run flavor="main":
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ "{{ flavor }}" == "nvidia" ]]; then
        TAG="{{ default_tag }}-nvidia"
    else
        TAG="{{ default_tag }}"
    fi

    {{ PODMAN }} run -it --rm \
        --privileged \
        "localhost/{{ image_name }}:${TAG}" \
        /bin/bash

# ============================================
# VM Recipes
# ============================================

# Run ISO in local VM with virt-manager
[group('VM')]
run-iso-local iso_file:
    #!/usr/bin/bash
    set -euo pipefail

    if [[ ! -f "{{ iso_file }}" ]]; then
        echo "Error: ISO file not found: {{ iso_file }}"
        exit 1
    fi

    ISO_PATH="$(realpath {{ iso_file }})"
    VM_NAME="hypercube-test-$$"

    # Calculate RAM size (half of available, max 8G)
    mem_free=$(awk '/MemAvailable/ { printf "%.0f\n", $2/1024/1024 }' /proc/meminfo)
    ram_size=$(( mem_free > 16 ? 8 : (mem_free > 8 ? mem_free / 2 : 4) ))

    echo "Starting VM: ${VM_NAME}"
    echo "Close virt-manager window to destroy VM"

    # Run with virt-install (transient VM, destroyed on shutdown)
    virt-install \
        --name "${VM_NAME}" \
        --memory $(( ram_size * 1024 )) \
        --vcpus $(( $(nproc) / 2 > 0 ? $(nproc) / 2 : 1 )) \
        --cdrom "${ISO_PATH}" \
        --disk size=64,format=qcow2,bus=virtio \
        --os-variant fedora-unknown \
        --boot uefi \
        --transient \
        --destroy-on-exit \
        --autoconsole graphical

# ============================================
# ISO Recipes
# ============================================

# Clone or update Titanoboa repository
[group('ISO')]
[private]
_titanoboa-setup:
    #!/usr/bin/bash
    set -euo pipefail
    if [[ -d "_titanoboa" ]]; then
        echo "Updating Titanoboa..."
        git -C _titanoboa pull --ff-only || true
    else
        echo "Cloning Titanoboa..."
        git clone --depth 1 "https://github.com/binarypie-dev/titanoboa.git" _titanoboa
    fi
    # Patch Titanoboa for local builds:
    # - Add --policy=missing to avoid re-pulling existing images
    # - Add --tls-verify=false for insecure local registries
    sed -i 's/podman pull /podman pull --tls-verify=false --policy=missing /' _titanoboa/Justfile
    sed -i 's/PODMAN }} pull /PODMAN }} pull --tls-verify=false --policy=missing /' _titanoboa/Justfile

# Build ISO from local image using a temporary local registry
[group('ISO')]
build-iso-local flavor="main": _titanoboa-setup
    #!/usr/bin/bash
    set -euo pipefail

    REGISTRY_PORT=5000
    REGISTRY_NAME="hypercube-registry"

    if [[ "{{ flavor }}" == "nvidia" ]]; then
        TAG="{{ default_tag }}-nvidia"
        ISO_NAME="{{ image_name }}-nvidia.iso"
    else
        TAG="{{ default_tag }}"
        ISO_NAME="{{ image_name }}.iso"
    fi

    LOCAL_IMAGE="localhost/{{ image_name }}:${TAG}"

    # Get the host IP address that the chroot can reach
    # Use the default route interface IP, or fall back to hostname -I
    HOST_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || hostname -I | awk '{print $1}')
    if [[ -z "$HOST_IP" ]]; then
        echo "Error: Could not determine host IP address"
        exit 1
    fi
    REGISTRY_IMAGE="${HOST_IP}:${REGISTRY_PORT}/{{ image_name }}:${TAG}"

    echo "Building ISO for ${LOCAL_IMAGE}..."
    echo "Using registry at ${HOST_IP}:${REGISTRY_PORT}"

    # Check if image exists in user storage
    ID=$({{ PODMAN }} images --filter reference="${LOCAL_IMAGE}" --format "{{{{.ID}}}}")
    if [[ -z "$ID" ]]; then
        echo "Error: Image ${LOCAL_IMAGE} not found. Run 'just build {{ flavor }}' first."
        exit 1
    fi

    # Cleanup function
    cleanup() {
        echo "Stopping local registry..."
        {{ SUDO }} {{ PODMAN }} stop "${REGISTRY_NAME}" 2>/dev/null || true
        {{ SUDO }} {{ PODMAN }} rm "${REGISTRY_NAME}" 2>/dev/null || true
    }
    trap cleanup EXIT

    # Stop any existing registry container from a previous failed build
    {{ SUDO }} {{ PODMAN }} stop "${REGISTRY_NAME}" 2>/dev/null || true
    {{ SUDO }} {{ PODMAN }} rm "${REGISTRY_NAME}" 2>/dev/null || true

    # Copy image to root podman storage if running as non-root
    if [[ "${UID}" -gt 0 ]]; then
        echo "Copying image to root podman storage..."
        COPYTMP=$(mktemp -p "${PWD}" -d -t podman_scp.XXXXXXXXXX)
        {{ SUDO }} TMPDIR=${COPYTMP} {{ PODMAN }} image scp "${UID}@localhost::${LOCAL_IMAGE}" root@localhost::"${LOCAL_IMAGE}"
        rm -rf "${COPYTMP}"
    fi

    # Start local registry bound to all interfaces
    echo "Starting local registry on port ${REGISTRY_PORT}..."
    {{ SUDO }} {{ PODMAN }} run -d --rm \
        --name "${REGISTRY_NAME}" \
        -p 0.0.0.0:${REGISTRY_PORT}:5000 \
        docker.io/library/registry:2

    # Wait for registry to be ready
    echo "Waiting for registry to be ready..."
    for i in {1..30}; do
        if curl -s "http://${HOST_IP}:${REGISTRY_PORT}/v2/" > /dev/null 2>&1; then
            echo "Registry is ready"
            break
        fi
        sleep 1
    done

    # Tag and push image to local registry
    echo "Pushing image to local registry..."
    {{ SUDO }} {{ PODMAN }} tag "${LOCAL_IMAGE}" "${REGISTRY_IMAGE}"
    {{ SUDO }} {{ PODMAN }} push --tls-verify=false "${REGISTRY_IMAGE}"

    # Save project root for later
    PROJECT_ROOT="${PWD}"

    # Copy iso_files to _titanoboa so they're available at /app/iso_files inside the chroot
    echo "Copying iso_files to _titanoboa..."
    rm -rf _titanoboa/iso_files
    cp -r iso_files _titanoboa/iso_files

    # Build ISO with Titanoboa
    # livesys=1 enables livesys-scripts from binarypie/hypercube COPR (includes Hyprland support)
    # HOOK_post_rootfs installs Anaconda and copies live ISO configs
    # Parameters (positional): image livesys flatpaks_file compression extra_kargs container_image polkit livesys_repo
    cd _titanoboa
    {{ SUDO }} HOOK_post_rootfs="${PROJECT_ROOT}/iso_files/hook-post-rootfs.sh" just build \
        "${REGISTRY_IMAGE}" \
        1 \
        "${PROJECT_ROOT}/flatpaks/system-flatpaks.list" \
        squashfs \
        NONE \
        "${REGISTRY_IMAGE}" \
        1 \
        binarypie/hypercube

    # Stop registry before moving ISO (while sudo is still cached)
    cleanup
    trap - EXIT

    # Move ISO to project root
    if [[ -f "output.iso" ]]; then
        mv output.iso "${PROJECT_ROOT}/${ISO_NAME}"
        echo ""
        echo "========================================"
        echo "ISO built successfully: ${ISO_NAME}"
        echo "========================================"
    else
        echo "Error: ISO build failed."
        exit 1
    fi

# Build ISO from GHCR image
[group('ISO')]
build-iso-ghcr flavor="main": _titanoboa-setup
    #!/usr/bin/bash
    set -euo pipefail

    REGISTRY="ghcr.io/{{ repo_organization }}"

    if [[ "{{ flavor }}" == "nvidia" ]]; then
        TAG="latest-nvidia"
        ISO_NAME="{{ image_name }}-nvidia.iso"
    else
        TAG="latest"
        ISO_NAME="{{ image_name }}.iso"
    fi

    IMAGE_FULL="${REGISTRY}/{{ image_name }}:${TAG}"

    echo "Building ISO for ${IMAGE_FULL}..."

    # Save project root for later
    PROJECT_ROOT="${PWD}"

    # Copy iso_files to _titanoboa so they're available at /app/iso_files inside the chroot
    echo "Copying iso_files to _titanoboa..."
    rm -rf _titanoboa/iso_files
    cp -r iso_files _titanoboa/iso_files

    # livesys=1 enables livesys-scripts from binarypie/hypercube COPR (includes Hyprland support)
    # HOOK_post_rootfs installs Anaconda and copies live ISO configs
    # Parameters (positional): image livesys flatpaks_file compression extra_kargs container_image polkit livesys_repo
    cd _titanoboa
    {{ SUDO }} HOOK_post_rootfs="${PROJECT_ROOT}/iso_files/hook-post-rootfs.sh" just build \
        "${IMAGE_FULL}" \
        1 \
        "${PROJECT_ROOT}/flatpaks/system-flatpaks.list" \
        squashfs \
        NONE \
        "${IMAGE_FULL}" \
        1 \
        binarypie/hypercube

    if [[ "${UID}" -gt 0 ]]; then
        {{ SUDO }} chown "${UID}:$(id -g)" -R "${PWD}"
    fi

    if [[ -f "output.iso" ]]; then
        mv output.iso "../${ISO_NAME}"
        echo ""
        echo "========================================"
        echo "ISO built successfully: ${ISO_NAME}"
        echo "========================================"
    else
        echo "Error: ISO build failed."
        exit 1
    fi

# Run ISO in QEMU VM
[group('ISO')]
run-iso iso_file:
    #!/usr/bin/bash
    set -euo pipefail

    if [[ ! -f "{{ iso_file }}" ]]; then
        echo "Error: ISO file not found: {{ iso_file }}"
        exit 1
    fi

    # Find available port
    port=8006
    while grep -q :${port} <<< $(ss -tunalp); do
        port=$(( port + 1 ))
    done
    echo "Using Port: ${port}"
    echo "Connect to http://localhost:${port}"

    # Calculate RAM size
    mem_free=$(awk '/MemAvailable/ { printf "%.0f\n", $2/1024/1024 - 1 }' /proc/meminfo)
    ram_size=$(( mem_free > 64 ? mem_free / 2 : (mem_free > 8 ? 8 : (mem_free < 3 ? 3 : mem_free)) ))

    # Run QEMU container
    {{ PODMAN }} run --rm --privileged \
        --pull=newer \
        --publish "127.0.0.1:${port}:8006" \
        --env "CPU_CORES=$(( $(nproc) / 2 > 0 ? $(nproc) / 2 : 1 ))" \
        --env "RAM_SIZE=${ram_size}G" \
        --env "DISK_SIZE=64G" \
        --env "TPM=Y" \
        --env "GPU=Y" \
        --env "BOOT_MODE=windows_secure" \
        --device=/dev/kvm \
        --volume "$(realpath {{ iso_file }})":"/boot.iso" \
        ghcr.io/qemus/qemu &

    sleep 3
    xdg-open http://localhost:${port}

# ============================================
# Verification Recipes
# ============================================

# Verify container image signature
[group('Verify')]
verify-container image tag:
    #!/usr/bin/env bash
    set -euo pipefail

    IMAGE_REF="ghcr.io/{{ repo_organization }}/{{ image }}:{{ tag }}"

    echo "Verifying signature for: ${IMAGE_REF}"

    cosign verify \
        --key cosign.pub \
        "${IMAGE_REF}"

    echo "Signature verified successfully!"

# ============================================
# Utility Recipes
# ============================================

# Clean build artifacts
[group('Utility')]
clean:
    #!/usr/bin/bash
    set -eoux pipefail
    rm -rf _build* _titanoboa
    rm -f previous.manifest.json changelog.md output.env
    rm -rf output/
    rm -f *.iso

# Lint bash scripts with shellcheck
[group('Lint')]
lint:
    #!/usr/bin/env bash
    set -eoux pipefail
    if ! command -v shellcheck &> /dev/null; then
        echo "shellcheck not found. Please install it."
        exit 1
    fi
    find . -type f -name "*.sh" -exec shellcheck {} \;

# Format bash scripts with shfmt
[group('Lint')]
format:
    #!/usr/bin/env bash
    set -eoux pipefail
    if ! command -v shfmt &> /dev/null; then
        echo "shfmt not found. Please install it."
        exit 1
    fi
    find . -type f -name "*.sh" -exec shfmt --write {} \;

# Check Just syntax
[group('Just')]
check:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
        echo "Checking syntax: $file"
        just --unstable --fmt --check -f "$file"
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt --check -f Justfile

# Fix Just syntax
[group('Just')]
fix:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
        echo "Fixing syntax: $file"
        just --unstable --fmt -f "$file"
    done
    echo "Fixing syntax: Justfile"
    just --unstable --fmt -f Justfile || exit 1
