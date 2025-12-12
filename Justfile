export image_name := env("IMAGE_NAME", "hypercube")
export default_tag := env("DEFAULT_TAG", "latest")
export base_image := env("BASE_IMAGE", "ghcr.io/ublue-os/bluefin-dx:stable-daily")
export base_image_nvidia := env("BASE_IMAGE_NVIDIA", "ghcr.io/ublue-os/bluefin-dx-nvidia:stable-daily")

export SUDOIF := if `id -u` == "0" { "" } else { "sudo" }
export PODMAN := if path_exists("/usr/bin/podman") == "true" { "/usr/bin/podman" } else { "podman" }

[private]
default:
    @just --list

# Check Just Syntax
[group('Just')]
check:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt --check -f Justfile

# Fix Just Syntax
[group('Just')]
fix:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt -f Justfile || { exit 1; }

# Clean Repo
[group('Utility')]
clean:
    #!/usr/bin/bash
    set -eoux pipefail
    touch _build
    find *_build* -exec rm -rf {} \;
    rm -f previous.manifest.json
    rm -f changelog.md
    rm -f output.env
    rm -rf output/
    rm -rf _titanoboa/
    rm -f *.iso

# Build the image using the specified parameters
[group('Build')]
build $target_image=image_name $tag=default_tag $base_img=base_image:
    #!/usr/bin/env bash
    set -euo pipefail

    BUILD_ARGS=()
    BUILD_ARGS+=("--build-arg" "BASE_IMAGE={{ base_img }}")

    if [[ -z "$(git status -s)" ]]; then
        BUILD_ARGS+=("--build-arg" "SHA_HEAD_SHORT=$(git rev-parse --short HEAD)")
    fi

    podman build \
        "${BUILD_ARGS[@]}" \
        --pull=newer \
        --tag "{{ target_image }}:{{ tag }}" \
        .

# Build the regular (non-NVIDIA) variant
[group('Build')]
build-regular $target_image=image_name:
    @just build "{{ target_image }}" "{{ default_tag }}" "{{ base_image }}"

# Build the NVIDIA variant
[group('Build')]
build-nvidia $target_image=image_name:
    @just build "{{ target_image }}" "{{ default_tag }}-nvidia" "{{ base_image_nvidia }}"

# Build both variants (regular and NVIDIA)
[group('Build')]
build-all $target_image=image_name:
    @echo "Building regular variant..."
    @just build-regular "{{ target_image }}"
    @echo "Building NVIDIA variant..."
    @just build-nvidia "{{ target_image }}"

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

# Build a live ISO using Titanoboa (requires sudo)
[group('ISO')]
build-iso $target_image=image_name $tag=default_tag: _titanoboa-setup
    #!/usr/bin/bash
    set -euo pipefail

    IMAGE_FULL="localhost/{{ target_image }}:{{ tag }}"

    echo "Building ISO for ${IMAGE_FULL}..."
    echo ""

    # Check if image exists in user podman
    ID=$(${PODMAN} images --filter reference="${IMAGE_FULL}" --format '{{ '{{.ID}}' }}')
    if [[ -z "$ID" ]]; then
        echo "Error: Image ${IMAGE_FULL} not found. Run 'just build-regular' first."
        exit 1
    fi

    # Copy image from user podman to root podman using podman image scp
    if [[ "${UID}" -gt 0 ]]; then
        echo "Copying image to root podman storage..."
        COPYTMP=$(mktemp -p "${PWD}" -d -t podman_scp.XXXXXXXXXX)
        ${SUDOIF} TMPDIR=${COPYTMP} ${PODMAN} image scp "${UID}@localhost::${IMAGE_FULL}" root@localhost::"${IMAGE_FULL}"
        rm -rf "${COPYTMP}"
    fi

    # Build ISO with Titanoboa
    cd _titanoboa
    ${SUDOIF} just build "${IMAGE_FULL}"

    # Fix ownership
    if [[ "${UID}" -gt 0 ]]; then
        ${SUDOIF} chown "${UID}:$(id -g)" -R "${PWD}"
    fi

    # Move ISO to project root
    if [[ -f "output.iso" ]]; then
        mv output.iso "../{{ image_name }}-regular.iso"
        echo ""
        echo "=========================================="
        echo "ISO built successfully: {{ image_name }}-regular.iso"
    else
        echo ""
        echo "=========================================="
        echo "Error: ISO build failed."
        exit 1
    fi

# Build a live ISO for the NVIDIA variant using Titanoboa
[group('ISO')]
build-iso-nvidia $target_image=image_name $tag=(default_tag + "-nvidia"): _titanoboa-setup
    #!/usr/bin/bash
    set -euo pipefail

    IMAGE_FULL="localhost/{{ target_image }}:{{ tag }}"

    echo "Building ISO for ${IMAGE_FULL}..."
    echo ""

    # Check if image exists in user podman
    ID=$(${PODMAN} images --filter reference="${IMAGE_FULL}" --format '{{ '{{.ID}}' }}')
    if [[ -z "$ID" ]]; then
        echo "Error: Image ${IMAGE_FULL} not found. Run 'just build-nvidia' first."
        exit 1
    fi

    # Copy image from user podman to root podman using podman image scp
    if [[ "${UID}" -gt 0 ]]; then
        echo "Copying image to root podman storage..."
        COPYTMP=$(mktemp -p "${PWD}" -d -t podman_scp.XXXXXXXXXX)
        ${SUDOIF} TMPDIR=${COPYTMP} ${PODMAN} image scp "${UID}@localhost::${IMAGE_FULL}" root@localhost::"${IMAGE_FULL}"
        rm -rf "${COPYTMP}"
    fi

    # Build ISO with Titanoboa
    cd _titanoboa
    ${SUDOIF} just build "${IMAGE_FULL}"

    # Fix ownership
    if [[ "${UID}" -gt 0 ]]; then
        ${SUDOIF} chown "${UID}:$(id -g)" -R "${PWD}"
    fi

    # Move ISO to project root
    if [[ -f "output.iso" ]]; then
        mv output.iso "../{{ image_name }}-nvidia.iso"
        echo ""
        echo "=========================================="
        echo "ISO built successfully: {{ image_name }}-nvidia.iso"
    else
        echo ""
        echo "=========================================="
        echo "Error: ISO build failed."
        exit 1
    fi

# Build container and then create ISO (regular variant)
[group('ISO')]
rebuild-iso: build-regular build-iso

# Build container and then create ISO (NVIDIA variant)
[group('ISO')]
rebuild-iso-nvidia: build-nvidia build-iso-nvidia

# Run a virtual machine from an ISO using qemu container
[group('VM')]
run-vm-iso iso_file:
    #!/usr/bin/bash
    set -euo pipefail

    if [[ ! -f "{{ iso_file }}" ]]; then
        echo "Error: ISO file not found: {{ iso_file }}"
        exit 1
    fi

    # Determine an available port to use
    port=8006
    while grep -q :${port} <<< $(ss -tunalp); do
        port=$(( port + 1 ))
    done
    echo "Using Port: ${port}"
    echo "Connect to http://localhost:${port}"

    # Ram Size
    mem_free=$(awk '/MemAvailable/ { printf "%.0f\n", $2/1024/1024 - 1 }' /proc/meminfo)
    ram_size=$(( mem_free > 64 ? mem_free / 2 : (mem_free > 8 ? 8 : (mem_free < 3 ? 3 : mem_free)) ))

    # Set up the arguments for running the VM
    run_args=()
    run_args+=(--rm --privileged)
    run_args+=(--pull=newer)
    run_args+=(--publish "127.0.0.1:${port}:8006")
    run_args+=(--env "CPU_CORES=$(( $(nproc) / 2 > 0 ? $(nproc) / 2 : 1 ))")
    run_args+=(--env "RAM_SIZE=${ram_size}G")
    run_args+=(--env "DISK_SIZE=64G")
    run_args+=(--env "TPM=Y")
    run_args+=(--env "GPU=Y")
    run_args+=(--env "BOOT_MODE=windows_secure")
    run_args+=(--device=/dev/kvm)
    run_args+=(--volume "$(realpath {{ iso_file }})":"/boot.iso")
    run_args+=(ghcr.io/qemus/qemu)

    # Run the VM and open the browser to connect
    podman run "${run_args[@]}" &
    sleep 3
    xdg-open http://localhost:${port}

# Runs shellcheck on all Bash scripts
[group('Lint')]
lint:
    #!/usr/bin/env bash
    set -eoux pipefail
    if ! command -v shellcheck &> /dev/null; then
        echo "shellcheck could not be found. Please install it."
        exit 1
    fi
    /usr/bin/find . -iname "*.sh" -type f -exec shellcheck "{}" ';'

# Runs shfmt on all Bash scripts
[group('Lint')]
format:
    #!/usr/bin/env bash
    set -eoux pipefail
    if ! command -v shfmt &> /dev/null; then
        echo "shfmt could not be found. Please install it."
        exit 1
    fi
    /usr/bin/find . -iname "*.sh" -type f -exec shfmt --write "{}" ';'
