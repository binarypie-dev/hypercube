# vim: set ft=make :
# Hypercube devcube — containerized IDE + parallel-agent orchestration
#
# Neovim/LazyVim, the AI agents (Claude Code, Codex, Antigravity, gh), the dev
# toolchain, and zellij + workmux ship as a single portable podman image. A thin
# wrapper at ~/.local/bin/devc runs it: `devc` opens the workmux parallel-agent
# workspace, and `devc nvim` / `devc claude` / `devc codex` / `devc agy` /
# `devc zellij` launch a single tool. Each project gets its OWN home volume
# (derived from the launch path), so AI logins persist per workspace and never
# leak between projects. Personal plugin overrides live in
# ~/.config/hypercube/nvim/lua/plugins/.

image := "ghcr.io/binarypie-dev/devcube:latest"
wrapper := "/usr/share/hypercube/config/devcube/scripts/devcube.sh"
# Per-project home volumes share this prefix (see devcube.sh DEVCUBE_HOME_PREFIX).
volume_prefix := "hypercube-devcube-home"

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
    echo "Baked config (nvim/fish/zellij/workmux) refreshes automatically on the"
    echo "next launch — no reset needed. For nvim plugin updates run ':Lazy update'"
    echo "(or ':Lazy restore' to match the image's pinned versions) inside nvim."

# WARNING: removes plugin state, sessions, AND AI CLI logins stored in the volumes.
# Reset persisted state in all per-project home volumes so the next launch re-seeds.
devcube-reset:
    #!/usr/bin/bash
    set -euo pipefail

    read -p "Remove ALL per-project home volumes ({{volume_prefix}}-*) (plugin state + AI logins)? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        podman volume ls -q | grep '^{{volume_prefix}}' | xargs -r podman volume rm -f
        echo "Home volumes removed. The next 'devc' launch will re-seed from the image."
    fi

    read -p "Also remove ALL per-project worktree volumes (devcube-wt-*)? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        podman volume ls -q | grep '^devcube-wt-' | xargs -r podman volume rm -f
        echo "Worktree volumes removed."
    else
        echo "Kept per-project worktree volumes."
    fi

# No home volume is mounted (state is per-project, and this is a scratch shell),
# so /root is ephemeral, though the entrypoint still lays down the baked config.
# Open a debug shell inside a throwaway devcube container.
devcube-shell:
    #!/usr/bin/bash
    set -euo pipefail
    exec podman run --rm -it --init \
        --user 0:0 --security-opt label=disable \
        -e DEVCUBE=1 -e TERM \
        -v "$(pwd):$(pwd):rw" -w "$(pwd)" \
        {{image}} bash
