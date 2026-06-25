#!/usr/bin/env bash
# devcube orchestrator preflight — baked into the image as `devcube-orchestrate`.
#
# Runs INSIDE the container, immediately before the zellij/workmux session, and
# enforces a single orchestrator per project. Two orchestrators on the same
# project share one /worktrees volume + workmux state (XDG_STATE_HOME); running
# them at once races and corrupts that per-project state, after which every later
# launch on the folder fails with "permission denied" until the volume is wiped.
#
# Detection is one advisory file lock (flock) on the per-project /worktrees
# volume. That volume is shared across this project's containers and the host
# kernel is shared, so the lock is visible to every same-project orchestrator.
# It is taken on a file descriptor that the exec'd session process inherits, so
# the kernel holds it for exactly that process's lifetime and releases it the
# instant the process exits — even on crash or kill. No PIDs, no host-side state,
# no stale locks to reclaim: liveness is the lock itself. A second launch is
# refused immediately. This is why the guard lives in the image, not the host
# wrapper — it keys off real session liveness rather than guesswork.
#
# Usage: devcube-orchestrate <cmd> [args...]   (e.g. `devcube-orchestrate zellij`)
set -euo pipefail

lock="/worktrees/.devcube-orchestrator.lock"

# Fail open everywhere: a missing flock, a non-orchestrator invocation (no
# /worktrees), or an unwritable volume must never block a legitimate launch —
# at worst the guard is a no-op. It only ever *refuses* on a confirmed conflict.
if ! command -v flock >/dev/null 2>&1 || [ ! -w /worktrees ]; then
	exec "$@"
fi

# Open the lock fd (9). With /worktrees confirmed writable above this won't fail
# in practice; guard it anyway and fail open if it somehow does.
if ! exec 9>"$lock"; then
	exec "$@"
fi

if ! flock -n 9; then
	echo "devc: an orchestrator session is already running for this project." >&2
	echo "      A second one would share its /worktrees volume + workmux state and" >&2
	echo "      corrupt it. Switch to the running session (or quit it) and retry, or" >&2
	echo "      launch a single tool that needs no shared state:" >&2
	echo "        devc nvim | devc claude | devc codex | devc agy" >&2
	exit 1
fi

# Lock held on fd 9. exec the session so it inherits the fd and holds the lock
# for its whole lifetime; the kernel frees it when the session process exits.
exec "$@"
