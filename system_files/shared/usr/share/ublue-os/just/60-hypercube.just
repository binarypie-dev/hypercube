# vim: set ft=make :
# Hypercube general commands

# Show Hypercube developer environment status
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
