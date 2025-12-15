# Hypercube Build System
# Aligned with Bluefin patterns for consistency

# Configuration
export repo_organization := env("REPO_ORGANIZATION", "binarypie-dev")
export image_name := env("IMAGE_NAME", "hypercube")
export base_image := env("BASE_IMAGE", "ghcr.io/ublue-os/bluefin-dx")
export base_image_nvidia := env("BASE_IMAGE_NVIDIA", "ghcr.io/ublue-os/bluefin-dx-nvidia")
export default_tag := env("DEFAULT_TAG", "stable-daily")
export rechunker_image := "ghcr.io/hhd-dev/rechunk:v1.0.3"

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
build flavor="main" ghcr="0" rechunk="0":
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

    # Rechunk if requested
    if [[ "{{ rechunk }}" == "1" ]]; then
        just rechunk "{{ image_name }}" "${TAG}"
        just load-rechunk "{{ image_name }}" "${TAG}"
    fi

    echo ""
    echo "========================================"
    echo "Build complete: ${IMAGE_FULL}"
    echo "========================================"

# Build with rechunking enabled (recommended for production)
[group('Build')]
build-rechunk flavor="main":
    @just build {{ flavor }} 0 1

# Build for GHCR push (rootful, with rechunking)
[group('Build')]
build-ghcr flavor="main":
    @just build {{ flavor }} 1 1

# Build both flavors
[group('Build')]
build-all:
    @echo "Building main flavor..."
    @just build-rechunk main
    @echo ""
    @echo "Building nvidia flavor..."
    @just build-rechunk nvidia

# Rechunk image for optimized OCI layers
[group('Build')]
[private]
rechunk image tag:
    #!/usr/bin/env bash
    set -euo pipefail

    IMAGE_FULL="localhost/{{ image }}:{{ tag }}"
    OUTPUT_DIR="${PWD}/_rechunk_output"

    echo "Rechunking: ${IMAGE_FULL}"

    rm -rf "${OUTPUT_DIR}"
    mkdir -p "${OUTPUT_DIR}"

    # Run rechunker container
    {{ PODMAN }} run --rm \
        --privileged \
        --security-opt label=disable \
        -v "${OUTPUT_DIR}:/output" \
        -v /var/lib/containers:/var/lib/containers \
        {{ rechunker_image }} \
        "${IMAGE_FULL}" \
        /output

    echo "Rechunk output saved to: ${OUTPUT_DIR}"

# Load rechunked image into podman
[group('Build')]
[private]
load-rechunk image tag:
    #!/usr/bin/env bash
    set -euo pipefail

    OUTPUT_DIR="${PWD}/_rechunk_output"
    IMAGE_FULL="{{ image }}:{{ tag }}"

    if [[ ! -d "${OUTPUT_DIR}" ]]; then
        echo "Error: Rechunk output not found at ${OUTPUT_DIR}"
        exit 1
    fi

    echo "Loading rechunked image..."

    # Load the OCI image
    {{ PODMAN }} load -i "${OUTPUT_DIR}/oci-archive.tar"

    # Tag it properly
    LOADED_IMAGE=$({{ PODMAN }} images --format "{{`{{.ID}}`}}" | head -1)
    {{ PODMAN }} tag "${LOADED_IMAGE}" "${IMAGE_FULL}"

    # Cleanup
    rm -rf "${OUTPUT_DIR}"

    echo "Loaded: ${IMAGE_FULL}"

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
        git clone --depth 1 "https://github.com/ublue-os/titanoboa.git" _titanoboa
    fi
    # Patch Titanoboa to use --policy=missing for local image builds
    sed -i 's/PODMAN }} pull /PODMAN }} pull --policy=missing /' _titanoboa/Justfile
    sed -i 's/podman pull /podman pull --policy=missing /' _titanoboa/Justfile

# Build ISO from local image
[group('ISO')]
build-iso flavor="main": _titanoboa-setup
    #!/usr/bin/bash
    set -euo pipefail

    if [[ "{{ flavor }}" == "nvidia" ]]; then
        TAG="{{ default_tag }}-nvidia"
        ISO_NAME="{{ image_name }}-nvidia.iso"
    else
        TAG="{{ default_tag }}"
        ISO_NAME="{{ image_name }}.iso"
    fi

    IMAGE_FULL="localhost/{{ image_name }}:${TAG}"

    echo "Building ISO for ${IMAGE_FULL}..."

    # Check if image exists
    ID=$({{ PODMAN }} images --filter reference="${IMAGE_FULL}" --format '{{`{{.ID}}`}}')
    if [[ -z "$ID" ]]; then
        echo "Error: Image ${IMAGE_FULL} not found. Run 'just build-rechunk {{ flavor }}' first."
        exit 1
    fi

    # Copy image to root podman storage if running as non-root
    if [[ "${UID}" -gt 0 ]]; then
        echo "Copying image to root podman storage..."
        COPYTMP=$(mktemp -p "${PWD}" -d -t podman_scp.XXXXXXXXXX)
        {{ SUDO }} TMPDIR=${COPYTMP} {{ PODMAN }} image scp "${UID}@localhost::${IMAGE_FULL}" root@localhost::"${IMAGE_FULL}"
        rm -rf "${COPYTMP}"
    fi

    # Build ISO with Titanoboa
    cd _titanoboa
    {{ SUDO }} just build "${IMAGE_FULL}"

    # Fix ownership
    if [[ "${UID}" -gt 0 ]]; then
        {{ SUDO }} chown "${UID}:$(id -g)" -R "${PWD}"
    fi

    # Move ISO to project root
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

    cd _titanoboa
    {{ SUDO }} just build "${IMAGE_FULL}"

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
    rm -rf _build* _titanoboa _rechunk_output
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
