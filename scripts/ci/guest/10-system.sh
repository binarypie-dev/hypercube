#!/usr/bin/env bash
# Stage 1: the booted system. Boot finished, no failed units, bootc and
# rpm-ostree status, Hypercube os-release, greetd and its cage greeter.
# Sourced after 00-lib.sh (see vm-smoke.sh).

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
