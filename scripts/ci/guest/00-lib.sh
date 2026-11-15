#!/usr/bin/env bash
# Shared setup for the in-VM checks. vm-smoke.sh concatenates
# scripts/ci/guest/*.sh in order and runs them as one script, as root, over
# SSH, so the helpers and the failure count here are shared by every stage.
#
# Env (forwarded by vm-smoke.sh):
#   ALLOWED_FAILED_UNITS       system units allowed to be failed in a VM
#   ALLOWED_FAILED_USER_UNITS  user units allowed to be failed in the session
#   NIRI_TIMEOUT               seconds to wait for the niri session (120)
#   NIRI_REQUIRE_OUTPUTS       1 = niri must have an output (virgl GPU);
#                              0 = no 3D GPU, skip output-dependent checks
#                              when niri refused software rendering

set -uo pipefail

ALLOWED_FAILED_UNITS="${ALLOWED_FAILED_UNITS:-}"
ALLOWED_FAILED_USER_UNITS="${ALLOWED_FAILED_USER_UNITS:-}"
NIRI_TIMEOUT="${NIRI_TIMEOUT:-120}"
NIRI_REQUIRE_OUTPUTS="${NIRI_REQUIRE_OUTPUTS:-1}"

# Throwaway test account. The VM disk is a discarded overlay.
CI_USER="hypercube-ci"
CI_PASSWORD="hypercube-ci-Passw0rd"

# Screenshots are copied back to the host (.vm/ci/screenshots) afterwards.
SHOT_DIR=/var/tmp/ci-screenshots
mkdir -p "${SHOT_DIR}"
chmod 0777 "${SHOT_DIR}"

failures=0
pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; failures=$((failures + 1)); }
skip() { echo "SKIP: $*"; echo "::warning title=smoke check skipped::$*"; }
section() { echo; echo "=== $* ==="; }
indent() { sed 's/^/    /'; }

# Wait until a command succeeds, up to $1 seconds.
wait_for() {
    local timeout="$1"; shift
    local end=$((SECONDS + timeout))
    until "$@" &>/dev/null; do
        ((SECONDS >= end)) && return 1
        sleep 2
    done
}

# Screenshot a Wayland compositor's output with grim (wlr-screencopy works on
# both cage and niri). Usage: screenshot <name> <uid> <wayland display>
screenshot() {
    local name="$1" uid="$2" display="$3"
    [[ -n "${display}" ]] || return 0
    local user
    user="$(id -nu "${uid}" 2>/dev/null)" || return 0
    if runuser -u "${user}" -- env XDG_RUNTIME_DIR="/run/user/${uid}" WAYLAND_DISPLAY="${display}" \
        grim "${SHOT_DIR}/${name}.png" 2>/dev/null; then
        echo "    screenshot: ${name}.png"
    else
        echo "    (screenshot ${name} failed)"
    fi
}
