#!/usr/bin/env bash
# devcube-session — run and manage a project's session, from INSIDE the container.
#
# The devc wrapper routes both session launches and `devc session <sub>` here, so
# all session logic lives in the image (not the host wrapper). Subcommands:
#
#   run <cmd...>    take the per-project lock and exec <cmd> holding it, so only
#                   one session runs per project. Used by devc to launch
#                   zellij/workmux.
#   list           list this project's zellij sessions
#   stop [name...]  stop running session(s) — a specific one, else all
#   remove [name...] delete saved session state — a specific one, else all
#
# Single-instance: two sessions on one project share its /worktrees volume +
# workmux state (XDG_STATE_HOME); racing them corrupts it, after which every
# later launch on the folder fails with "permission denied". `run` guards against
# that with one advisory flock on the shared /worktrees volume, held on a fd the
# exec'd session inherits — so the kernel holds it for exactly the session's
# lifetime and frees it the instant it exits (crash/kill included). No PIDs, no
# host state, no stale locks: liveness is the lock itself.
#
# list/stop/remove act through zellij, whose IPC sockets live on the shared
# per-project /worktrees volume (ZELLIJ_SOCKET_DIR, set by devc), so this
# container sees and can act on sessions started by other containers of the same
# project.
set -euo pipefail

lock="/worktrees/.devcube-session.lock"

cmd="${1:-list}"
if [ $# -gt 0 ]; then shift; fi

case "$cmd" in
run)
	[ $# -ge 1 ] || {
		echo "devcube-session run: needs a command to run" >&2
		exit 2
	}
	# Fail open: a missing flock or unwritable /worktrees must never block a
	# launch — at worst the guard is a no-op. It only refuses on a real conflict.
	if ! command -v flock >/dev/null 2>&1 || [ ! -w /worktrees ]; then
		exec "$@"
	fi
	# /worktrees confirmed writable, so opening the lock fd won't fail here.
	exec 9>"$lock"
	if ! flock -n 9; then
		echo "devc: a session is already running for this project." >&2
		echo "      A second one would share its /worktrees volume + workmux state" >&2
		echo "      and corrupt it. Reattach to it, stop it with 'devc session stop'," >&2
		echo "      or launch a single tool that needs no shared state:" >&2
		echo "        devc nvim | devc claude | devc codex | devc agy" >&2
		exit 1
	fi
	# Lock held on fd 9; exec the session so it inherits the fd and holds the lock
	# for its whole lifetime; the kernel frees it when the session process exits.
	exec "$@"
	;;
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
	echo "usage: devcube-session run <cmd...> | list | stop [name...] | remove [name...]"
	;;
*)
	echo "devcube-session: unknown subcommand '$cmd'" >&2
	echo "usage: devcube-session run <cmd...> | list | stop [name...] | remove [name...]" >&2
	exit 1
	;;
esac
