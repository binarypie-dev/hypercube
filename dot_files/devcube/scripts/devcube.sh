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
#   devc session .. -> manage running sessions: list | stop | remove (host-side)
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

# ---------------------------------------------------------------------------
# `devc session` — manage running sessions and their persisted per-project
# state. Sessions are the podman containers devc launches (labeled io.devcube.*),
# so this is host-side (podman) and never enters a container:
#   devc session list               list running devcube sessions
#   devc session stop [<path>|all]   stop a running session (default: this project)
#   devc session remove [<path>]     remove a project's worktree/state volume --
#                                    the per-project state that gets corrupted by
#                                    concurrent sessions; refuses while one is up.
# ---------------------------------------------------------------------------
if [ "${1:-}" = session ]; then
	shift || true
	sub="${1:-list}"
	if [ $# -gt 0 ]; then shift; fi

	if ! command -v podman >/dev/null 2>&1; then
		echo "devc: podman not found; 'devc session' needs it." >&2
		exit 1
	fi

	# The git repo root for a path (or the path itself when not in a repo) -- the
	# same key devc launches under, so labels and volume names line up.
	session_project_dir() {
		local d="${1:-$(pwd -P)}"
		d="$(cd "$d" 2>/dev/null && pwd -P || printf '%s' "$d")"
		git -C "$d" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$d"
	}
	# The per-project worktree/state volume name (must match the launch path below).
	session_volume() {
		local pd slug phash
		pd="$1"
		slug="$(basename "$pd" | tr -c 'a-zA-Z0-9_.-' '-')"
		phash="$(printf '%s' "$pd" | cksum | cut -d' ' -f1)"
		printf '%s' "${DEVCUBE_WT_PREFIX:-devcube-wt}-${slug}-${phash}"
	}

	case "$sub" in
	list | ls)
		podman ps --filter "label=io.devcube.session=1" \
			--format 'table {{.Names}}\t{{index .Labels "io.devcube.tool"}}\t{{index .Labels "io.devcube.project"}}\t{{.Status}}'
		;;
	stop)
		if [ "${1:-}" = all ]; then
			ids="$(podman ps -q --filter "label=io.devcube.session=1")"
			label="all sessions"
		else
			pd="$(session_project_dir "${1:-}")"
			ids="$(podman ps -q --filter "label=io.devcube.project=${pd}")"
			label="'${pd}'"
		fi
		if [ -z "${ids:-}" ]; then
			echo "devc: no running session for ${label}." >&2
			exit 1
		fi
		# shellcheck disable=SC2086
		podman stop $ids
		;;
	remove | rm)
		pd="$(session_project_dir "${1:-}")"
		if [ -n "$(podman ps -q --filter "label=io.devcube.project=${pd}")" ]; then
			echo "devc: a session for '${pd}' is still running -- run 'devc session stop' first." >&2
			exit 1
		fi
		vol="$(session_volume "$pd")"
		if podman volume rm -f "$vol" >/dev/null 2>&1; then
			echo "devc: removed session state volume '${vol}' for '${pd}'."
		else
			echo "devc: no session state volume for '${pd}' (nothing to remove)."
		fi
		;;
	-h | --help | help)
		echo "usage: devc session [list | stop [<path>|all] | remove [<path>]]"
		;;
	*)
		echo "devc session: unknown subcommand '${sub}'" >&2
		echo "usage: devc session [list | stop [<path>|all] | remove [<path>]]" >&2
		exit 1
		;;
	esac
	exit 0
fi

# The tool to run is the first argument; default to the workmux workspace.
TOOL="${1:-workmux}"
case "$TOOL" in
nvim | claude | codex | agy | zellij | workmux)
	if [ $# -gt 0 ]; then shift; fi
	;;
*)
	echo "devc: unknown command '$TOOL'" >&2
	echo "usage: devc [nvim|claude|codex|agy|zellij|workmux] [args...]  (no args -> workmux)" >&2
	echo "       devc session [list|stop|remove] ...                   (manage sessions)" >&2
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

# Default: run the tool with only the project mounted. The session workspaces
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

	extra=(
		# Worktrees live here (podman auto-creates the volume on first mount).
		-v "${wt_volume}:/worktrees:rw"
		-e WORKMUX_BACKEND=zellij
		# Keep workmux's agent state on the per-project volume too, so it's
		# isolated from other projects and survives restarts.
		-e XDG_STATE_HOME=/worktrees/.local/state
	)
	# Only one session may run per project: two would share this project's
	# /worktrees volume + workmux state (XDG_STATE_HOME above) and racing them
	# corrupts it, which then breaks every later launch on the folder ("permission
	# denied") until the volume is removed. `devcube-session` (baked into the
	# image) enforces single-instance IN-CONTAINER, via an advisory lock on the
	# shared /worktrees volume, and refuses a second launch. Keeping the guard in
	# the image -- not here on the host -- means it relies on real session liveness
	# (the lock is held by the live session process and freed by the kernel when it
	# exits) rather than host-side PID guesswork. Single-tool entry points mount no
	# shared state, so they stay concurrent and skip the guard.
	#
	# zellij 0.44.x fails ("There is no active session!") when --layout and
	# --session are passed together, so we never combine them. The session name
	# isn't load-bearing -- worktrees + workmux state persist via the volumes
	# above, not the zellij session -- so we let zellij auto-name it. workmux
	# operates on whatever the current session is, named or not.
	if [ "$TOOL" = workmux ]; then
		container_cmd=(devcube-session zellij --layout workmux)
	else
		container_cmd=(devcube-session zellij)
	fi
	;;
esac

args=(
	run --rm --interactive --tty --init
	--user 0:0
	--security-opt label=disable
	--hostname "$TOOL"
	# Labels let `devc session list|stop|remove` find this container (and derive
	# its per-project state volume) from the host without a fixed --name.
	--label io.devcube.session=1
	--label "io.devcube.tool=${TOOL}"
	--label "io.devcube.project=${project_dir}"
	-e DEVCUBE=1
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
