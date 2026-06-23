# vim: set ft=make :
# Hypercube devcube — containerized IDE + parallel-agent orchestration
#
# Neovim/LazyVim, the AI agents (Claude Code, Codex, Antigravity, gh), the dev
# toolchain, and zellij + workmux ship as a single portable podman image. A thin
# wrapper at ~/.local/bin/devc runs it: `devc` opens the workmux parallel-agent
# workspace, and `devc nvim` / `devc claude` / `devc codex` / `devc agy` /
# `devc zellij` launch a single tool. One home volume is shared across them, so
# AI logins persist. Personal plugin overrides live in
# ~/.config/hypercube/nvim/lua/plugins/.

image := "ghcr.io/binarypie-dev/devcube:latest"
wrapper := "/usr/share/hypercube/config/devcube/scripts/devcube.sh"
volume := "hypercube-devcube-home"

# Pull the image and install the devc wrapper to ~/.local/bin
devcube-setup:
    #!/usr/bin/bash
    set -euo pipefail

    echo "Pulling devcube image ({{image}})..."
    echo "(several GB on first run)"
    podman pull {{image}}

    mkdir -p "$HOME/.local/bin" "$HOME/.config/hypercube/nvim/lua/plugins"
    install -m 0755 {{wrapper}} "$HOME/.local/bin/devc"

    echo ""
    echo "Setup complete! Run 'devc' for the parallel-agent workspace (workmux),"
    echo "or 'devc nvim' / 'devc claude' / 'devc codex' / 'devc agy' / 'devc zellij'"
    echo "to launch a single tool."
    echo "Personal nvim overrides go in: ~/.config/hypercube/nvim/lua/plugins/"

# Pull the latest image and refresh the wrapper
devcube-upgrade:
    #!/usr/bin/bash
    set -euo pipefail

    echo "Pulling latest devcube image..."
    podman pull {{image}}
    install -m 0755 {{wrapper}} "$HOME/.local/bin/devc"

    echo "Done!"
    echo "Tip: run ':Lazy update' inside nvim to update plugins. Baked config"
    echo "updates (zellij/workmux/fish) only apply to a fresh home volume — run"
    echo "'ujust devcube-reset' to re-seed (this clears AI logins)."

# Reset persisted state so the next launch re-seeds from the image.
# WARNING: removes plugin state, sessions, AND AI CLI logins stored in the volume.
devcube-reset:
    #!/usr/bin/bash
    set -euo pipefail

    read -p "Remove the {{volume}} volume (plugin state + AI logins)? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        podman volume rm -f {{volume}} 2>/dev/null || true
        echo "Volume removed. The next 'devc' launch will re-seed from the image."
    fi

    read -p "Also remove ALL per-project worktree volumes (devcube-wt-*)? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        podman volume ls -q | grep '^devcube-wt-' | xargs -r podman volume rm -f
        echo "Worktree volumes removed."
    else
        echo "Kept per-project worktree volumes."
    fi

# Open a debug shell inside a throwaway devcube container
devcube-shell:
    #!/usr/bin/bash
    set -euo pipefail
    exec podman run --rm -it --init \
        --user 0:0 --security-opt label=disable \
        -e DEVCUBE=1 -e TERM \
        -v {{volume}}:/root \
        -v "$(pwd):$(pwd):rw" -w "$(pwd)" \
        {{image}} bash
