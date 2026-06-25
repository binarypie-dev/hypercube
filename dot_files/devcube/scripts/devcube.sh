#!/usr/bin/env bash
# devcube — containerized IDE + parallel-agent launcher.
#
# One podman image bakes Neovim (LazyVim) + the AI coding agents + the dev
# toolchain + zellij/workmux + a fish/starship shell. This wrapper is installed as
# `devc`. It is intentionally thin: it sets up the container (mounts, host facts)
# and forwards the first argument + the rest to `devcube-session` INSIDE the
# image, which decides what to actually run. All per-tool behavior lives there, so
# adding or changing a command means editing the image, not this file.
#
#   devc            -> workmux parallel-agent workspace (a zellij session) -- default
#   devc zellij     -> a plain zellij multiplexer session
#   devc nvim       -> the editor (launch agents from inside it)
#   devc claude     -> Claude Code CLI, run directly
#   devc codex      -> OpenAI Codex CLI, run directly
#   devc agy        -> Antigravity CLI, run directly
#   devc session .. -> manage this project's sessions: list | stop | remove
#
# Extra args after the command are passed straight through (e.g. `devc nvim
# file.rs`, `devc claude --resume`, `devc session stop my-sess`). All entry points
# share the same home volume, so AI-CLI logins persist -- log in once, every tool
# is authed.
#
# The project mount is the git repo root (discovered from the launch dir), or the
# launch dir itself when not in a repo. Each project also gets its own named
# worktree volume at /worktrees, where zellij/workmux keep per-project state that
# persists across restarts and never collides with another project's. Portable
# across Linux and macOS.
#
# Env overrides:
#   DEVCUBE_IMAGE      container image (default ghcr.io/binarypie-dev/devcube:latest)
#   DEVCUBE_VOLUME     named volume holding state + AI auth (default hypercube-devcube-home)
#   DEVCUBE_WT_PREFIX  prefix for the per-project worktree volume (default devcube-wt)
set -euo pipefail

# Bare `devc` opens the workmux workspace. Otherwise forward args verbatim.
[ $# -gt 0 ] || set -- workmux

IMAGE="${DEVCUBE_IMAGE:-ghcr.io/binarypie-dev/devcube:latest}"
VOLUME="${DEVCUBE_VOLUME:-hypercube-devcube-home}"
OVERRIDE_DIR="$HOME/.config/hypercube/nvim"

# Personal overrides are layered on top of the baked config. Ensure the dir
# exists so the bind mount and `{ import = "plugins" }` always resolve.
mkdir -p "$OVERRIDE_DIR/lua/plugins"

# Physical path so symlinks resolve identically on host and in the container.
workdir="$(pwd -P)"

# Resolve the project root host-side -- podman needs the bind-mount path (and the
# per-project volume name below) before the container exists. Mount the whole git
# repo so the repo-root `.git` and the full project are visible inside; fall back
# to the launch dir when not in a repo.
git_root="$(git -C "$workdir" rev-parse --show-toplevel 2>/dev/null || true)"
project_dir="${git_root:-$workdir}"

# Per-project worktree/session volume. The name is repo-root-derived so a
# project's state persists, is shared no matter which subdir you launch from, and
# never collides with another project's (cksum is on both Linux and macOS, keeping
# this portable). What lives inside the volume is the image's business -- the
# wrapper only mounts it.
slug="$(basename "$project_dir" | tr -c 'a-zA-Z0-9_.-' '-')"
phash="$(printf '%s' "$project_dir" | cksum | cut -d' ' -f1)"
wt_volume="${DEVCUBE_WT_PREFIX:-devcube-wt}-${slug}-${phash}"

args=(
	run --rm --interactive --tty --init
	--user 0:0
	--security-opt label=disable
	--hostname "$1"
	-e DEVCUBE=1
	-e TERM
	-e COLORTERM
	# Home volume: state + plugin updates + AI auth. Seeded from the image's /root
	# on first run (podman copy-up); never a fixed --name, so sessions run
	# concurrently.
	-v "${VOLUME}:/root"
	# Per-project worktree/session volume (podman auto-creates it on first mount).
	-v "${wt_volume}:/worktrees:rw"
	# The project -- the git repo root, or the launch dir when not in a repo --
	# at the same path inside the container.
	-v "${project_dir}:${project_dir}:rw"
	# Personal plugin overrides (nested over the home volume).
	-v "${OVERRIDE_DIR}:/root/.config/hypercube/nvim:rw"
	-w "${project_dir}"
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

# Forward the command + args; devcube-session (in the image) does the rest.
exec podman "${args[@]}" "$IMAGE" devcube-session "$@"
