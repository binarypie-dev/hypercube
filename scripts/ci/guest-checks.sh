#!/usr/bin/env bash
# Smoke checks run inside a booted Hypercube VM, as root, over SSH.
# Driven by scripts/ci/vm-smoke.sh (`just smoke` / `just ci`); prints one
# PASS/FAIL line per check and exits non-zero if any check failed.
#
# Env (forwarded by vm-smoke.sh):
#   ALLOWED_FAILED_UNITS  space-separated units allowed to be failed in a VM
#   NIRI_TIMEOUT          seconds to wait for the niri session (default 120)

set -uo pipefail

ALLOWED_FAILED_UNITS="${ALLOWED_FAILED_UNITS:-}"
NIRI_TIMEOUT="${NIRI_TIMEOUT:-120}"
CI_USER="hypercube-ci"

failures=0
pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; failures=$((failures + 1)); }
section() { echo; echo "=== $* ==="; }

# Wait until a command succeeds, up to $1 seconds.
wait_for() {
    local timeout="$1"; shift
    local end=$((SECONDS + timeout))
    until "$@" &>/dev/null; do
        ((SECONDS >= end)) && return 1
        sleep 2
    done
}

section "Boot"
# Waits for boot to finish; "degraded" means at least one unit failed, which
# the next check reports in detail.
state="$(timeout 300 systemctl is-system-running --wait 2>/dev/null)"
echo "system state: ${state:-still starting after 300s}"
if [[ -z "${state}" || "${state}" == "starting" ]]; then
    fail "boot did not finish within 300s"
    systemctl list-jobs --no-pager 2>&1 | sed 's/^/    /'
fi

section "Failed units"
mapfile -t failed < <(systemctl --failed --no-legend --plain | awk '{print $1}')
unexpected=()
for unit in "${failed[@]}"; do
    [[ -z "${unit}" ]] && continue
    if [[ " ${ALLOWED_FAILED_UNITS} " == *" ${unit} "* ]]; then
        echo "allowed in VM: ${unit}"
    else
        unexpected+=("${unit}")
    fi
done
if ((${#unexpected[@]} == 0)); then
    pass "no failed units"
else
    fail "failed units: ${unexpected[*]}"
    for unit in "${unexpected[@]}"; do
        echo "--- ${unit}"
        systemctl status --no-pager --lines=15 "${unit}" 2>&1 | sed 's/^/    /'
    done
fi

section "bootc / rpm-ostree"
if bootc status >/dev/null 2>&1; then
    booted_image="$(bootc status --format=json 2>/dev/null | jq -r '.status.booted.image.image.image // empty')"
    if [[ -n "${booted_image}" ]]; then
        pass "bootc status: booted ${booted_image}"
    else
        fail "bootc status has no booted image"
        bootc status 2>&1 | sed 's/^/    /'
    fi
else
    fail "bootc status exited non-zero"
fi
if rpm-ostree status --json 2>/dev/null | jq -e '[.deployments[] | select(.booted)] | length == 1' >/dev/null; then
    pass "rpm-ostree status: exactly one booted deployment"
else
    fail "rpm-ostree status does not show a single booted deployment"
    rpm-ostree status 2>&1 | sed 's/^/    /'
fi
if grep -q '^ID=hypercube' /usr/lib/os-release; then
    pass "os-release is Hypercube"
else
    fail "os-release is not Hypercube"
fi

section "Greeter"
if systemctl is-active --quiet greetd.service; then
    pass "greetd.service is active"
else
    fail "greetd.service is not active"
    systemctl status --no-pager --lines=20 greetd.service 2>&1 | sed 's/^/    /'
fi
# First boot runs onboarding (initial_session) instead of the greeter; both
# run under cage, so either one counts as the greeter coming up.
if wait_for 60 pgrep -x cage; then
    session="$(pgrep -a -f 'hypercube-(greeter|onboard)' | head -1)"
    pass "cage is running (${session:-greeter process not identified})"
else
    fail "cage (greeter compositor) never started"
    journalctl -b -u greetd.service --no-pager -n 30 2>&1 | sed 's/^/    /'
fi

section "niri session"
# Log a throwaway user straight into niri through greetd, the same path a
# real login takes (PAM, logind seat, niri-session, niri.service). The VM has
# a virtual GPU with no display attached, so niri runs on a headless output.
if ! id "${CI_USER}" &>/dev/null; then
    useradd -m "${CI_USER}"
fi
cp /etc/greetd/config.toml /etc/greetd/config.toml.ci-backup
cat > /etc/greetd/config.toml <<GREETD
[terminal]
vt = 1

[default_session]
command = "cage -s -- ghostty-kiosk hypercube-greeter"
user = "greeter"

[initial_session]
command = "niri-session"
user = "${CI_USER}"
GREETD
systemctl restart greetd.service

ci_user_systemctl() { systemctl --user -M "${CI_USER}@" "$@"; }
if wait_for "${NIRI_TIMEOUT}" ci_user_systemctl is-active --quiet niri.service; then
    pass "niri.service is active for ${CI_USER}"

    niri_socket="$(ci_user_systemctl show-environment 2>/dev/null | sed -n 's/^NIRI_SOCKET=//p')"
    uid="$(id -u "${CI_USER}")"
    niri_msg() {
        runuser -u "${CI_USER}" -- env XDG_RUNTIME_DIR="/run/user/${uid}" NIRI_SOCKET="${niri_socket}" niri msg "$@"
    }
    outputs="$(niri_msg --json outputs 2>/dev/null | jq -r 'keys | join(", ")' 2>/dev/null)"
    if [[ -n "${outputs}" ]]; then
        pass "niri has outputs: ${outputs}"
    else
        fail "niri is running but reports no outputs (or IPC failed)"
    fi

    # The polkit agent (the admin password prompt) hangs off niri.service
    agent=hypercube-polkit-agent.service
    if ci_user_systemctl cat "${agent}" &>/dev/null; then
        if wait_for 30 ci_user_systemctl is-active --quiet "${agent}"; then
            pass "${agent} is active in the niri session"
        else
            fail "${agent} is not active in the niri session"
            ci_user_systemctl status --no-pager --lines=15 "${agent}" 2>&1 | sed 's/^/    /'
        fi
    fi
    if wait_for 30 pgrep -u "${CI_USER}" -x quickshell; then
        pass "quickshell is running"
    else
        fail "quickshell is not running in the niri session"
    fi
else
    fail "niri.service did not become active within ${NIRI_TIMEOUT}s"
    ci_user_systemctl status --no-pager --lines=30 niri.service 2>&1 | sed 's/^/    /'
    journalctl -b --no-pager -n 50 _UID="$(id -u "${CI_USER}")" 2>&1 | sed 's/^/    /'
fi

# Leave the VM as we found it (the disk is a throwaway overlay anyway)
mv /etc/greetd/config.toml.ci-backup /etc/greetd/config.toml

echo
if ((failures == 0)); then
    echo "All smoke checks passed"
else
    echo "${failures} smoke check(s) failed"
fi
exit $((failures > 0))
