# Hypercube DX (Developer Experience) Commands

# Enter the nvim-dev container (creates if needed)
nvim-dev:
    #!/usr/bin/bash
    set -euo pipefail

    if ! distrobox list | grep -q "nvim-dev"; then
        echo "Creating nvim-dev container (this pulls ~2GB image on first run)..."
        distrobox assemble create --file /etc/distrobox/distrobox.ini
    fi

    distrobox enter nvim-dev

# Export nvim to host for direct access
nvim-export:
    #!/usr/bin/bash
    set -euo pipefail

    if ! distrobox list | grep -q "nvim-dev"; then
        echo "Creating nvim-dev container..."
        distrobox assemble create --file /etc/distrobox/distrobox.ini
    fi

    echo "Exporting nvim to ~/.local/bin..."
    distrobox enter nvim-dev -- distrobox-export --bin /home/linuxbrew/.linuxbrew/bin/nvim --export-path ~/.local/bin
    echo ""
    echo "Done! You can now run 'nvim' directly from the host."

# Quick setup: create container + export nvim
nvim-setup:
    #!/usr/bin/bash
    set -euo pipefail

    echo "Setting up nvim-dev environment..."
    echo ""

    if ! distrobox list | grep -q "nvim-dev"; then
        echo "Creating nvim-dev container (this pulls ~2GB image on first run)..."
        distrobox assemble create --file /etc/distrobox/distrobox.ini
    else
        echo "Container nvim-dev already exists"
    fi

    echo ""
    echo "Exporting nvim to ~/.local/bin..."
    distrobox enter nvim-dev -- distrobox-export --bin /home/linuxbrew/.linuxbrew/bin/nvim --export-path ~/.local/bin

    echo ""
    echo "Setup complete! You can now run 'nvim' directly."

# Upgrade nvim-dev container to latest image
nvim-upgrade:
    #!/usr/bin/bash
    set -euo pipefail

    echo "Upgrading nvim-dev to latest image..."
    distrobox upgrade nvim-dev
    echo "Done!"

# Create distrobox containers from config
distrobox-assemble:
    #!/usr/bin/bash
    set -euo pipefail

    echo "Creating distrobox containers from /etc/distrobox/distrobox.ini..."
    distrobox assemble create --file /etc/distrobox/distrobox.ini
    echo ""
    echo "Containers created. Use 'distrobox list' to see them."

# List all distrobox containers
distrobox-list:
    distrobox list

# Create a new dev container based on Fedora toolbox
distrobox-dev name:
    #!/usr/bin/bash
    set -euo pipefail

    echo "Creating development container: {{ name }}"
    distrobox create --name "{{ name }}" --image registry.fedoraproject.org/fedora-toolbox:43
    echo ""
    echo "Container created. Enter with: distrobox enter {{ name }}"

# Create a Fedora container
distrobox-fedora name:
    #!/usr/bin/bash
    set -euo pipefail

    echo "Creating Fedora container: {{ name }}"
    distrobox create --name "{{ name }}" --image registry.fedoraproject.org/fedora:latest
    echo ""
    echo "Container created. Enter with: distrobox enter {{ name }}"

# Create an Ubuntu container
distrobox-ubuntu name:
    #!/usr/bin/bash
    set -euo pipefail

    echo "Creating Ubuntu container: {{ name }}"
    distrobox create --name "{{ name }}" --image docker.io/library/ubuntu:latest
    echo ""
    echo "Container created. Enter with: distrobox enter {{ name }}"

# Create an Arch Linux container
distrobox-arch name:
    #!/usr/bin/bash
    set -euo pipefail

    echo "Creating Arch Linux container: {{ name }}"
    distrobox create --name "{{ name }}" --image docker.io/library/archlinux:latest
    echo ""
    echo "Container created. Enter with: distrobox enter {{ name }}"

# Show developer environment status
dx-status:
    #!/usr/bin/bash
    set -euo pipefail

    echo "Hypercube DX Status"
    echo "==================="
    echo ""

    echo "Container Runtimes:"
    echo -n "  Podman: "
    podman --version 2>/dev/null || echo "not found"
    echo ""

    echo "Distrobox Containers:"
    distrobox list 2>/dev/null || echo "  (none)"
