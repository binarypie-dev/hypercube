# vim: set ft=make :
# Hypercube AI-first Neovim sandbox commands
#
# The editor and AI agents (Claude Code, Codex, Antigravity, gh) ship as a
# single portable podman image. A thin wrapper at ~/.local/bin/nvim runs it.
# Personal plugin overrides live in ~/.config/hypercube/nvim/lua/plugins/.

image := "ghcr.io/binarypie-dev/nvim-dev:latest"
wrapper := "/usr/share/hypercube/config/nvim/scripts/nvim.sh"
volume := "hypercube-nvim-home"

# Pull the image and install the nvim wrapper to ~/.local/bin
nvim-setup:
    #!/usr/bin/bash
    set -euo pipefail

    echo "Pulling Neovim sandbox image ({{image}})..."
    echo "(several GB on first run)"
    podman pull {{image}}

    mkdir -p "$HOME/.local/bin" "$HOME/.config/hypercube/nvim/lua/plugins"
    install -m 0755 {{wrapper}} "$HOME/.local/bin/nvim"

    echo ""
    echo "Setup complete! Run 'nvim' to launch the AI-first editor."
    echo "Personal overrides go in: ~/.config/hypercube/nvim/lua/plugins/"

# Pull the latest image and refresh the wrapper
nvim-upgrade:
    #!/usr/bin/bash
    set -euo pipefail

    echo "Pulling latest Neovim sandbox image..."
    podman pull {{image}}
    install -m 0755 {{wrapper}} "$HOME/.local/bin/nvim"

    echo "Done!"
    echo "Tip: run ':Lazy update' inside nvim to update plugins, or"
    echo "'ujust nvim-reset' to re-seed plugins from the new image."

# Reset persisted state so the next launch re-seeds from the image.
# WARNING: removes plugin state, sessions, AND AI CLI logins stored in the volume.
nvim-reset:
    #!/usr/bin/bash
    set -euo pipefail

    read -p "Remove the {{volume}} volume (plugin state + AI logins)? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        podman volume rm -f {{volume}} 2>/dev/null || true
        echo "Volume removed. The next 'nvim' launch will re-seed from the image."
    else
        echo "Cancelled."
    fi

# Open a debug shell inside a throwaway sandbox container
nvim-shell:
    #!/usr/bin/bash
    set -euo pipefail
    exec podman run --rm -it --init \
        --user 0:0 --security-opt label=disable \
        -e HYPERCUBE_NVIM=1 -e TERM \
        -v {{volume}}:/root \
        -v "$(pwd):$(pwd):rw" -w "$(pwd)" \
        {{image}} bash
