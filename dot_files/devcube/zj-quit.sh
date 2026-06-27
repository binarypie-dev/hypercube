#!/usr/bin/env bash
# zj-quit — the "quit devcube" prompt (bound to Ctrl+Space q in zellij).
#
# Launched in a floating zellij pane (see dot_files/zellij/config.kdl). It asks
# whether to keep the session before dropping back to your host shell:
#
#   Save     -> Quit the session. With session_serialization on, zellij keeps it
#               as a resurrectable session; the next `devc` reattaches to it
#               (same tabs / worktrees / panes). See devcube-session.sh.
#   Discard  -> Delete this session (and its serialized state) outright, so the
#               next `devc` starts fresh from the workmux layout.
#   Cancel   -> Close this prompt and stay where you are.
#
# The devcube image ships fzf, which renders the menu full-screen in the
# floating pane — arrow keys / type-to-filter, Enter to pick, Esc to cancel.
set -euo pipefail

# zellij exports the live session name into every pane.
session="${ZELLIJ_SESSION_NAME:-}"

choice="$(
	printf '%s\n' \
		'Save     — keep this session; devc resumes it next time' \
		'Discard  — delete this session; devc starts fresh next time' \
		'Cancel   — stay here' |
		fzf --reverse --no-info --cycle \
			--pointer='▶' \
			--prompt='quit devcube ▸ ' \
			--header='Save your session before quitting?' ||
		true
)"

case "$choice" in
Save*)
	# Quit -> resurrectable (serialization is enabled in config.kdl).
	exec zellij action quit
	;;
Discard*)
	# Kill the running session AND remove its serialized copy in one shot, so
	# nothing is left to resurrect. Fall back to a plain quit if, for whatever
	# reason, we don't know our own session name.
	if [ -n "$session" ]; then
		exec zellij delete-session "$session" --force
	else
		exec zellij action quit
	fi
	;;
*)
	# Cancel / Esc / empty — just close the floating pane.
	exit 0
	;;
esac
