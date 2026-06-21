#!/usr/bin/env bash
# Hypercube AI-first sandbox launcher.
#
# One podman image bakes Neovim (LazyVim) + the AI coding agents + the dev
# toolchain. This single wrapper is installed under several names; the name it
# is invoked as selects what runs inside the (otherwise identical) container:
#
#   nvim    -> the editor (launch agents from inside it) -- the default
#   claude  -> Claude Code CLI, run directly
#   codex   -> OpenAI Codex CLI, run directly
#   agy     -> Antigravity CLI, run directly
#
# All four share the same home volume, so AI-CLI logins persist across them --
# log in once (from nvim or any agent wrapper) and every entry point is authed.
#
# Mounts only the current project, your personal overrides, and a few host
# facts (git identity, SSH agent, terminal). Portable across Linux and macOS.
#
# Env overrides:
#   HYPERCUBE_NVIM_IMAGE   container image (default ghcr.io/binarypie-dev/nvim-dev:latest)
#   HYPERCUBE_NVIM_VOLUME  named volume holding state + AI auth (default hypercube-nvim-home)
set -euo pipefail

# What to run is chosen by the name we were invoked as (symlinks point here).
CMD="$(basename "$0")"
case "$CMD" in
    nvim | claude | codex | agy) ;;
    *) CMD=nvim ;;
esac

IMAGE="${HYPERCUBE_NVIM_IMAGE:-ghcr.io/binarypie-dev/nvim-dev:latest}"
VOLUME="${HYPERCUBE_NVIM_VOLUME:-hypercube-nvim-home}"
OVERRIDE_DIR="$HOME/.config/hypercube/nvim"

# Personal overrides are layered on top of the baked config. Ensure the dir
# exists so the bind mount and `{ import = "plugins" }` always resolve.
mkdir -p "$OVERRIDE_DIR/lua/plugins"

# Physical path so symlinks resolve identically on host and in the container.
workdir="$(pwd -P)"

args=(
    run --rm --interactive --tty --init
    --user 0:0
    --security-opt label=disable
    --hostname "$CMD"
    -e HYPERCUBE_NVIM=1
    -e TERM
    -e COLORTERM
    # State + plugin updates + AI auth. Empty volume is seeded from the image's
    # /root on first run (podman copy-up); never use a fixed container --name so
    # multiple sessions can run concurrently.
    -v "${VOLUME}:/root"
    # The project being edited, at the same path inside the container.
    -v "${workdir}:${workdir}:rw"
    # Personal plugin overrides (nested over the home volume).
    -v "${OVERRIDE_DIR}:/root/.config/hypercube/nvim:rw"
    -w "${workdir}"
)

# Read-only git identity (name/email/aliases) from the host.
if [ -f "$HOME/.gitconfig" ]; then
    args+=(-v "$HOME/.gitconfig:/root/.gitconfig:ro")
fi

# SSH agent forwarding on Linux. On macOS podman runs in a VM and the host
# agent socket isn't reachable, so we skip it there and rely on `gh auth login`
# (run once inside; persisted in the home volume) for git-over-HTTPS.
if [ "$(uname -s)" = "Linux" ] && [ -n "${SSH_AUTH_SOCK:-}" ] && [ -S "${SSH_AUTH_SOCK}" ]; then
    args+=(-v "${SSH_AUTH_SOCK}:${SSH_AUTH_SOCK}:rw" -e "SSH_AUTH_SOCK=${SSH_AUTH_SOCK}")
fi

exec podman "${args[@]}" "$IMAGE" "$CMD" "$@"
