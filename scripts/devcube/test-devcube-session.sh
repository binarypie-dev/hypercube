#!/bin/bash
# Test suite for devcube-session.sh — the attach-or-create zellij launcher that
# the `devc` wrapper runs inside the container.
#
# The script execs the real `zellij` binary, so to drive its branches in
# isolation we point ZELLIJ_BIN at a stub. The stub:
#
#   * answers `list-sessions` from the FAKE_SESSIONS env var (one session name
#     per line; empty -> behaves like zellij with no sessions: error to stderr,
#     non-zero exit), and
#   * records every other invocation (attach / delete-session / --session ...)
#     to FAKE_LOG, one argv per line, so a test can assert exactly what the
#     script asked zellij to do.
#
# This lets us cover the three states that matter: a saved/attachable session
# (Save), a deleted/absent session (Discard -> create fresh), and a wedged dead
# remnant left by an unsaved exit (clear it, then create fresh).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/../../dot_files/devcube/devcube-session.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

test_count=0
pass_count=0

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# A stub `zellij` on ZELLIJ_BIN. `list-sessions` is sourced from FAKE_SESSIONS;
# the "already exists, but is dead" wedge is modelled by FAKE_DEAD: while it's
# set, a create (`--session`) fails like real zellij until delete-session clears
# it (the stub removes the FAKE_DEAD marker file when asked to delete).
STUB="$WORK/zellij"
cat >"$STUB" <<'STUB_EOF'
#!/bin/bash
log() { printf '%s\n' "$*" >>"$FAKE_LOG"; }

case "$1" in
list-sessions)
	if [ -z "${FAKE_SESSIONS:-}" ]; then
		echo "No active zellij sessions found." >&2
		exit 1
	fi
	# Mimic `--no-formatting`: "<name> [Created ...]", name in the first field.
	while IFS= read -r s; do
		[ -n "$s" ] && printf '%s [Created 1s ago]\n' "$s"
	done <<<"$FAKE_SESSIONS"
	;;
delete-session)
	log "$*"
	# Clearing the wedge: drop the dead-remnant marker if present.
	[ -n "${FAKE_DEAD:-}" ] && rm -f "$FAKE_DEAD"
	;;
attach)
	log "$*"
	;;
--session)
	log "$*"
	# A live dead remnant makes `zellij --session` refuse to start.
	if [ -n "${FAKE_DEAD:-}" ] && [ -e "$FAKE_DEAD" ]; then
		echo "Session with name $2 already exists, but is dead." >&2
		exit 1
	fi
	;;
*)
	log "$*"
	;;
esac
STUB_EOF
chmod +x "$STUB"

# Run devcube-session.sh with the stub. Args: session [layout].
# Env in: FAKE_SESSIONS (newline list), FAKE_DEAD (marker file path or empty).
# Sets globals: RUN_RC, RUN_LOG (path to the recorded argv log).
run_script() {
	FAKE_LOG="$WORK/log.$test_count"
	: >"$FAKE_LOG"
	set +e
	ZELLIJ_BIN="$STUB" FAKE_LOG="$FAKE_LOG" \
		FAKE_SESSIONS="${FAKE_SESSIONS:-}" FAKE_DEAD="${FAKE_DEAD:-}" \
		bash "$SCRIPT" "$@" >/dev/null 2>&1
	RUN_RC=$?
	set -e
	RUN_LOG="$FAKE_LOG"
}

# Assert the recorded log matches the expected argv lines exactly.
check() {
	local test_name=$1
	local expected=$2
	test_count=$((test_count + 1))
	local actual
	actual="$(cat "$RUN_LOG")"
	if [[ "$RUN_RC" -eq 0 && "$actual" == "$expected" ]]; then
		printf "Test $test_count: $test_name\n  ${GREEN}✓ PASS${NC}\n\n"
		pass_count=$((pass_count + 1))
	else
		printf "Test $test_count: $test_name\n"
		printf "  ${RED}✗ FAIL${NC} (rc=$RUN_RC)\n"
		printf "    expected: %q\n" "$expected"
		printf "    actual:   %q\n\n" "$actual"
	fi
}

echo "Running tests for devcube-session.sh"
echo "=========================================="
echo ""

# 1. Saved session present -> resurrect/attach it, never create. (Save path.)
FAKE_SESSIONS="devcube-proj-123" FAKE_DEAD="" run_script "devcube-proj-123" "workmux"
check "attaches an existing (saved/resurrectable) session" \
	"attach devcube-proj-123"

# 2. No session at all (e.g. Discard deleted it) with a layout -> create fresh
#    with the layout. A stray delete-session first is fine (clears nothing).
FAKE_SESSIONS="" FAKE_DEAD="" run_script "devcube-proj-123" "workmux"
check "creates fresh with layout when no session exists" \
	"$(printf 'delete-session devcube-proj-123 --force\n--session devcube-proj-123 --new-session-with-layout workmux')"

# 3. No session and no layout -> create a fresh plain named session.
FAKE_SESSIONS="" FAKE_DEAD="" run_script "devcube-proj-123"
check "creates fresh plain session when no session and no layout" \
	"$(printf 'delete-session devcube-proj-123 --force\n--session devcube-proj-123')"

# 4. Unsaved exit left a wedged dead remnant: list-sessions doesn't surface it,
#    and a naive create would fail with "already exists, but is dead". The script
#    must clear it first, then create fresh and succeed. (The regression fix.)
DEAD_MARK="$WORK/dead.marker"
: >"$DEAD_MARK"
FAKE_SESSIONS="" FAKE_DEAD="$DEAD_MARK" run_script "devcube-proj-123" "workmux"
check "clears a dead remnant then creates fresh (unsaved-exit recovery)" \
	"$(printf 'delete-session devcube-proj-123 --force\n--session devcube-proj-123 --new-session-with-layout workmux')"

# 5. A different session is running, but not ours -> we don't attach to it; we
#    create our own. Guards against a loose substring match in list-sessions.
FAKE_SESSIONS="$(printf 'some-other-session\ndevcube-proj-999')" FAKE_DEAD="" \
	run_script "devcube-proj-123" "workmux"
check "ignores unrelated sessions and creates our own" \
	"$(printf 'delete-session devcube-proj-123 --force\n--session devcube-proj-123 --new-session-with-layout workmux')"

# Summary
echo "=========================================="
echo "Test Results: $pass_count/$test_count passed"
echo "=========================================="

if [[ $pass_count -eq $test_count ]]; then
	printf "${GREEN}All tests passed!${NC}\n"
	exit 0
else
	printf "${RED}Some tests failed${NC}\n"
	exit 1
fi
