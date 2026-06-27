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
set -euo pipefail

session="$1"
layout="${2:-}"

# A session of this name already exists (running or serialized/resurrectable)?
# `list-sessions` prints the name as the first field for both; awk matches it
# exactly. With no sessions it errors to stderr (suppressed) and prints nothing.
if zellij list-sessions --no-formatting 2>/dev/null |
	awk -v s="$session" '$1 == s { found = 1 } END { exit !found }'; then
	exec zellij attach "$session"
elif [ -n "$layout" ]; then
	exec zellij --session "$session" --new-session-with-layout "$layout"
else
	exec zellij --session "$session"
fi
