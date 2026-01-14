# vim: set ft=make :
# Hypercube Neovim development environment commands

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
