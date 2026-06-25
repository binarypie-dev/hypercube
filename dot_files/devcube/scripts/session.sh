#!/usr/bin/env bash
# devcube-session — the in-container dispatcher, baked into the image.
#
# The devc wrapper forwards the command + args here; this is where all per-tool
# behavior lives, so the host wrapper stays a thin pass-through. Commands:
#
#   nvim | claude | codex | agy   run the tool directly (single tools)
#   workmux                       launch the workmux workspace (guarded)
#   zellij                        launch a plain zellij session (guarded)
#   session list                  list this project's zellij sessions
#   session stop [name...]        stop running session(s) — one, or all
#   session remove [name...]      delete saved session state — one, or all
set -euo pipefail

lock="/worktrees/.devcube-session.lock"

# Per-project state lives on the /worktrees volume devc mounts. Set these only for
# the workspaces/management that use them, so single tools (nvim/claude/...) get a
# clean environment:
#   - XDG_STATE_HOME   : workmux's agent state, isolated per project + persistent
#   - ZELLIJ_SOCKET_DIR: zellij's IPC sockets on the shared volume, so every one
#     of this project's containers shares a session namespace — that's what lets
#     `session list`/`stop` see and act on a session running in another container
#     (zellij scans this dir to discover sessions)
#   - WORKMUX_BACKEND  : workmux's multiplexer (this image ships zellij, no tmux)
session_env() {
	export XDG_STATE_HOME=/worktrees/.local/state
	export ZELLIJ_SOCKET_DIR=/worktrees/.zellij/sock
	export WORKMUX_BACKEND=zellij
}

# Single-instance guard: two sessions on one project share its /worktrees volume +
# workmux state, and racing them corrupts it (every later launch on the folder
# then fails with "permission denied"). Take an advisory flock on the shared
# volume, then exec "$@" holding it on fd 9 — the kernel keeps the lock for exactly
# the session's lifetime and frees it the instant it exits (crash/kill included),
# so liveness is the lock itself: no PIDs, no host state, no stale locks. Fail open
# so a missing flock or unwritable volume never blocks a launch.
guard_and_exec() {
	if command -v flock >/dev/null 2>&1 && [ -w /worktrees ]; then
		exec 9>"$lock"
		if ! flock -n 9; then
			echo "devc: a session is already running for this project." >&2
			echo "      A second would share its /worktrees volume + workmux state and" >&2
			echo "      corrupt it. Reattach to it, stop it with 'devc session stop', or" >&2
			echo "      launch a single tool: devc nvim | devc claude | devc codex | devc agy." >&2
			exit 1
		fi
	fi
	exec "$@"
}

usage() {
	echo "usage: devc [nvim|claude|codex|agy|zellij|workmux] [args...]   (no args -> workmux)"
	echo "       devc session [list | stop [name...] | remove [name...]]"
}

tool="${1:-workmux}"
if [ $# -gt 0 ]; then shift; fi

case "$tool" in
nvim | claude | codex | agy)
	exec "$tool" "$@"
	;;
workmux)
	if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		echo "devc: workmux requires a git repository, but this folder isn't one." >&2
		echo "      cd into a repo (or run 'git init') and try again." >&2
		exit 1
	fi
	session_env
	# zellij 0.44.x errors ("There is no active session!") when --layout and
	# --session are combined, so we don't name the session; worktrees + workmux
	# state persist via /worktrees regardless, and workmux operates on whatever the
	# current session is, named or not.
	guard_and_exec zellij --layout workmux
	;;
zellij)
	session_env
	guard_and_exec zellij
	;;
session)
	session_env
	sub="${1:-list}"
	if [ $# -gt 0 ]; then shift; fi
	case "$sub" in
	list | ls)
		exec zellij list-sessions "$@"
		;;
	stop)
		if [ $# -gt 0 ]; then
			exec zellij kill-session "$@"
		fi
		exec zellij kill-all-sessions --yes
		;;
	remove | rm | delete)
		if [ $# -gt 0 ]; then
			exec zellij delete-session "$@"
		fi
		exec zellij delete-all-sessions --yes
		;;
	-h | --help | help)
		usage
		;;
	*)
		echo "devc session: unknown subcommand '$sub'" >&2
		usage >&2
		exit 1
		;;
	esac
	;;
-h | --help | help)
	usage
	;;
*)
	echo "devc: unknown command '$tool'" >&2
	usage >&2
	exit 1
	;;
esac
