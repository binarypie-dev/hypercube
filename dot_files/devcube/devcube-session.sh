#!/usr/bin/env bash
# devcube-session — attach-or-create a named zellij session inside the container.
#
# Runs INSIDE the devcube container (the `devc` wrapper invokes it as the
# container command), where the zellij sessions actually live. Given a stable
# per-project session name it either:
#
#   * resurrects/reattaches an existing session of that name (one left behind by
#     Ctrl+Space q -> Save, serialized under the persisted /root home volume), or
#   * starts a fresh session with the requested layout when none exists.
#
# This is what makes "close the devcube, reopen it later, same workspace" work.
#
# Why not `zellij --session NAME --layout L`? With --session present, --layout is
# interpreted as "add these tabs to the (not-yet-existing) session" and zellij
# errors with "There is no active session!". The flag that always starts a fresh
# named session with a layout is --new-session-with-layout, used below.
#
# Recovering from an unsaved exit. The home volume (/root) outlives any single
# `--rm` container, but the live zellij socket lives in the container's
# ephemeral /tmp. If a devcube is torn down WITHOUT going through Ctrl+Space q
# (the terminal/container is just killed), the socket dies with the container
# while a stale scrap of session state can linger on the persisted volume. zellij
# then refuses to reopen that name -- "session ... already exists, but is dead" --
# and the next `devc` wedges instead of recovering. So when no usable session of
# this name is left to attach to, we clear any dead remnant before creating a
# fresh one (see below). Cleanly saved sessions still resurrect; only the wedged
# leftovers get cleared.
set -euo pipefail

session="$1"
layout="${2:-}"

# The zellij binary, overridable so the logic can be exercised by tests with a
# stub on this seam (see scripts/devcube/test-devcube-session.sh). Defaults to
# the real `zellij` on PATH in the container.
zellij_bin="${ZELLIJ_BIN:-zellij}"

# Does a session of this name currently exist that we can attach to -- either
# running, or serialized/resurrectable (left by Ctrl+Space q -> Save, or by the
# periodic snapshot of a session we never cleanly closed)? `list-sessions` prints
# the name as the first field for both kinds, tagging the resurrectable ones; awk
# matches the name exactly. With no sessions it errors to stderr (suppressed) and
# prints nothing, so awk finds no match.
session_attachable() {
	"$zellij_bin" list-sessions --no-formatting 2>/dev/null |
		awk -v s="$session" '$1 == s { found = 1 } END { exit !found }'
}

if session_attachable; then
	# Running -> reattach; serialized -> resurrect. `attach` does both, restoring
	# the saved tabs / panes / worktrees.
	exec "$zellij_bin" attach "$session"
fi

# Nothing attachable by this name. A session killed uncleanly (container torn
# down without Ctrl+Space q) can still leave a *dead* remnant that list-sessions
# won't surface yet `zellij --session NAME` trips over with "already exists, but
# is dead" -- the wedged state that breaks the next `devc`. Clear any such remnant
# first; delete-session is a harmless no-op (non-zero, swallowed) when there's
# nothing to remove, so a truly first-run session is unaffected.
"$zellij_bin" delete-session "$session" --force >/dev/null 2>&1 || true

if [ -n "$layout" ]; then
	exec "$zellij_bin" --session "$session" --new-session-with-layout "$layout"
else
	exec "$zellij_bin" --session "$session"
fi
