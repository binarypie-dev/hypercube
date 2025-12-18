# Hypercube DX (Developer Experience) Commands

# Enter the bluefin-cli container (Homebrew environment)
brew:
    #!/usr/bin/bash
    set -euo pipefail

    # Check if bluefin-cli container exists
    if ! distrobox list | grep -q "bluefin-cli"; then
        echo "Creating bluefin-cli container..."
        distrobox assemble create --file /etc/distrobox/distrobox.ini
    fi

    distrobox enter bluefin-cli

# Run a brew command directly without entering the container
brew-run *args:
    #!/usr/bin/bash
    set -euo pipefail

    # Check if bluefin-cli container exists
    if ! distrobox list | grep -q "bluefin-cli"; then
        echo "Creating bluefin-cli container..."
        distrobox assemble create --file /etc/distrobox/distrobox.ini
    fi

    distrobox enter bluefin-cli -- brew {{ args }}

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

# Create a new dev container with common tools
distrobox-dev name:
    #!/usr/bin/bash
    set -euo pipefail

    echo "Creating development container: {{ name }}"
    distrobox create --name "{{ name }}" --image ghcr.io/ublue-os/bluefin-cli:latest
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
