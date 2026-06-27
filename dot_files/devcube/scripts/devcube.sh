#!/usr/bin/env bash
# devcube — containerized IDE + parallel-agent launcher.
#
# One podman image bakes Neovim (LazyVim) + the AI coding agents + the dev
# toolchain + zellij/workmux + a fish/starship shell. This single wrapper is
# installed as `devc`; the first argument selects what runs inside the
# (otherwise identical) container:
#
#   devc            -> workmux parallel-agent workspace (a zellij session) -- default
#   devc zellij     -> a plain zellij multiplexer session
#   devc nvim       -> the editor (launch agents from inside it)
#   devc claude     -> Claude Code CLI, run directly
#   devc codex      -> OpenAI Codex CLI, run directly
#   devc agy        -> Antigravity CLI, run directly
#
# Extra args after the tool are passed through (e.g. `devc nvim file.rs`,
# `devc claude --resume`). All entry points share the same home volume, so
# AI-CLI logins persist across them -- log in once and every tool is authed.
#
# zellij/workmux run the parallel-agent flow: each `workmux add <branch>`
# creates a git worktree on a PER-PROJECT named volume mounted at /worktrees,
# so worktrees (and workmux's state) persist across restarts and never collide
# with another project's. The project mount is the git repo root (discovered from
# the launch dir), or the launch dir itself when not in a repo; workmux requires
# a repo, the other tools don't. Plus your personal overrides and a few host
# facts (git identity, SSH agent, terminal). Portable across Linux and macOS.
#
# Env overrides:
#   DEVCUBE_IMAGE      container image (default ghcr.io/binarypie-dev/devcube:latest)
#   DEVCUBE_VOLUME     named volume holding state + AI auth (default hypercube-devcube-home)
#   DEVCUBE_WT_PREFIX  prefix for the per-project worktree volume (default devcube-wt)
set -euo pipefail

# The tool to run is the first argument; default to the workmux workspace.
TOOL="${1:-workmux}"
case "$TOOL" in
nvim | claude | codex | agy | zellij | workmux)
	if [ $# -gt 0 ]; then shift; fi
	;;
*)
	echo "devc: unknown command '$TOOL'" >&2
	echo "usage: devc [nvim|claude|codex|agy|zellij|workmux] [args...]  (no args -> workmux)" >&2
	exit 1
	;;
esac

IMAGE="${DEVCUBE_IMAGE:-ghcr.io/binarypie-dev/devcube:latest}"
VOLUME="${DEVCUBE_VOLUME:-hypercube-devcube-home}"
OVERRIDE_DIR="$HOME/.config/hypercube/nvim"

# Personal overrides are layered on top of the baked config. Ensure the dir
# exists so the bind mount and `{ import = "plugins" }` always resolve.
mkdir -p "$OVERRIDE_DIR/lua/plugins"

# Physical path so symlinks resolve identically on host and in the container.
workdir="$(pwd -P)"

# Mount the whole git repo, not just the launch dir, so the repo-root `.git` and
# the full project are visible inside the container (git/workmux need this). Fall
# back to the launch dir when not in a repo. workmux REQUIRES a repo -- it creates
# git worktrees -- so it errors out here; nvim/claude/codex/agy don't care.
git_root="$(git -C "$workdir" rev-parse --show-toplevel 2>/dev/null || true)"
project_dir="${git_root:-$workdir}"
if [ "$TOOL" = workmux ] && [ -z "$git_root" ]; then
	echo "devc: workmux requires a git repository, but '$workdir' isn't in one." >&2
	echo "      cd into a repo (or run 'git init') and try again." >&2
	exit 1
fi

# Default: run the tool with only the project mounted. The orchestrators
# (zellij/workmux) additionally get a per-project worktree volume + the zellij
# backend, and run inside a zellij session.
container_cmd=("$TOOL")
extra=()
case "$TOOL" in
zellij | workmux)
	# Stable, repo-root-derived names so a project's worktrees + workmux state
	# persist across restarts, are shared no matter which subdir you launch from,
	# and never collide with another project's. cksum is available on both Linux
	# and macOS (the wrapper stays portable).
	slug="$(basename "$project_dir" | tr -c 'a-zA-Z0-9_.-' '-')"
	phash="$(printf '%s' "$project_dir" | cksum | cut -d' ' -f1)"
	wt_volume="${DEVCUBE_WT_PREFIX:-devcube-wt}-${slug}-${phash}"
	# Stable, per-project zellij session name so closing the devcube (Ctrl+Space
	# q -> Save) and reopening it resumes the SAME session. The home volume
	# (/root) is shared across every project, so the name must be unique per
	# project -> include phash. zellij session names can't contain '.', so the
	# slug's dots are squashed to '-' (the volume name keeps them; it's separate).
	session="devcube-$(printf '%s' "$slug" | tr '.' '-')-${phash}"
	extra=(
		# Worktrees live here (podman auto-creates the volume on first mount).
		-v "${wt_volume}:/worktrees:rw"
		-e WORKMUX_BACKEND=zellij
		# Keep workmux's agent state on the per-project volume too, so it's
		# isolated from other projects and survives restarts.
		-e XDG_STATE_HOME=/worktrees/.local/state
	)
	# Hand off to the in-image launcher, which resurrects the named session if it
	# exists (left by Ctrl+Space q -> Save) or creates it fresh otherwise. It has
	# to run inside the container because that's where the sessions live, and it
	# uses --new-session-with-layout (not --layout) to dodge zellij 0.44.x's
	# "There is no active session!" when --layout is combined with --session.
	# workmux operates on whatever the current session is.
	if [ "$TOOL" = workmux ]; then
		container_cmd=(devcube-session "$session" workmux)
	else
		container_cmd=(devcube-session "$session")
	fi
	;;
esac

args=(
	run --rm --interactive --tty --init
	--user 0:0
	--security-opt label=disable
	--hostname "$TOOL"
	-e DEVCUBE=1
	# Host OS (Darwin/Linux). The container is always Linux, so `uname` inside
	# can't tell a Mac host from a Linux one -- but the clipboard behaves
	# differently per host (see nvim's clipboard config), so we pass it through.
	-e "DEVCUBE_HOST_OS=$(uname -s)"
	-e TERM
	-e COLORTERM
	"${extra[@]}"
	# State + plugin updates + AI auth. Empty volume is seeded from the image's
	# /root on first run (podman copy-up); never use a fixed container --name so
	# multiple sessions can run concurrently.
	-v "${VOLUME}:/root"
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

exec podman "${args[@]}" "$IMAGE" "${container_cmd[@]}" "$@"
