#!/usr/bin/env bash
# Stage 3: inside the logged-in niri session. Output, user services, keyring
# unlocked by the login password, SSH agent, portal, Quickshell (layers, IPC,
# hub, QML errors) and a terminal window. Sourced after 20-login.sh.

if ((session_up)); then
    sleep 10 # let autostart (Quickshell, swaybg, swayidle, ...) settle

    session_var() { ci_user_systemctl show-environment 2>/dev/null | sed -n "s/^$1=//p"; }
    wl_display="$(session_var WAYLAND_DISPLAY)"
    [[ -n "${wl_display}" ]] || wl_display="$(wayland_display_of "${ci_uid}")"
    niri_socket="$(session_var NIRI_SOCKET)"
    [[ -n "${niri_socket}" ]] || niri_socket="$(compgen -G "/run/user/${ci_uid}/niri.*.sock" | head -1)"
    # Run a command as the test user with their session's full environment
    # (the user manager's, which niri and everything it spawns get:
    # XDG_CONFIG_DIRS from environment.d, WAYLAND_DISPLAY, NIRI_SOCKET, ...).
    # Lines systemctl had to shell-quote are skipped.
    mapfile -t session_env < <(ci_user_systemctl show-environment 2>/dev/null | grep -v "\$'")
    in_session() {
        user_env "${session_env[@]}" WAYLAND_DISPLAY="${wl_display}" NIRI_SOCKET="${niri_socket}" "$@"
    }
    niri_json() { in_session niri msg --json "$@" 2>/dev/null; }
    shot() { screenshot "$1" "${ci_uid}" "${wl_display}"; }

    section "niri output"
    niri_outputs() { niri_json outputs | jq -er 'select(length > 0) | keys | join(", ")'; }
    niri_log() { journalctl -b --no-pager _UID="${ci_uid}" _COMM=niri 2>/dev/null; }
    have_output=0
    if wait_for 30 niri_outputs; then
        have_output=1
        pass "niri has outputs: $(niri_outputs)"
        shot 03-desktop
    elif [[ "${NIRI_REQUIRE_OUTPUTS}" != "1" ]] && niri_log | grep -q 'software EGL renderers are skipped'; then
        skip "niri has no output: the VM has no 3D GPU and niri refuses software rendering; output-dependent checks are skipped (run with VM_GPU=virgl)"
    else
        fail "niri reports no outputs, or its IPC failed (socket: ${niri_socket:-not found})"
        in_session niri msg outputs 2>&1 | indent
        for status in /sys/class/drm/card*-*/status; do
            [[ -e "${status}" ]] && echo "    $(basename "$(dirname "${status}")"): $(cat "${status}")"
        done
        niri_log | tail -n 40 | indent
    fi

    section "User services"
    mapfile -t failed < <(ci_user_systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}')
    unexpected=()
    for unit in "${failed[@]}"; do
        [[ -z "${unit}" ]] && continue
        if [[ " ${ALLOWED_FAILED_USER_UNITS} " == *" ${unit} "* ]]; then
            echo "allowed in VM: ${unit}"
        else
            unexpected+=("${unit}")
        fi
    done
    if ((${#unexpected[@]} == 0)); then
        pass "no failed user units"
    else
        fail "failed user units: ${unexpected[*]}"
        for unit in "${unexpected[@]}"; do
            ci_user_systemctl status --no-pager --lines=15 "${unit}" 2>&1 | indent
        done
    fi
    for unit in hypercube-polkit-agent.service pipewire.service wireplumber.service; do
        if wait_for 30 ci_user_systemctl is-active --quiet "${unit}"; then
            pass "${unit} is active"
        else
            fail "${unit} is not active"
            ci_user_systemctl status --no-pager --lines=15 "${unit}" 2>&1 | indent
        fi
    done
    # Match the command line: the kernel's process name is cut at 15
    # characters (gnome-keyring-daemon shows as "gnome-keyring-d").
    for proc in quickshell swaybg swayidle gnome-keyring-daemon; do
        if wait_for 20 pgrep -u "${CI_USER}" -f "(^|/)${proc}( |$)"; then
            pass "${proc} is running"
        else
            fail "${proc} is not running"
        fi
    done

    section "Keyring and SSH agent"
    # The login keyring is unlocked by PAM with the login password
    # (pam_gnome_keyring); a locked one means the password never reached it.
    locked="$(user_env timeout 20 busctl --user get-property org.freedesktop.secrets \
        /org/freedesktop/secrets/collection/login org.freedesktop.Secret.Collection Locked 2>&1)"
    if [[ "${locked}" == "b false" ]]; then
        pass "login keyring is unlocked by the login password"
    else
        fail "login keyring is not unlocked after login (Locked: ${locked:-no answer})"
    fi
    if command -v secret-tool >/dev/null; then
        if printf 'ci-secret' | user_env timeout 20 secret-tool store --label=hypercube-ci ci smoke &&
            [[ "$(user_env timeout 20 secret-tool lookup ci smoke)" == "ci-secret" ]]; then
            pass "secrets can be stored and read back without a prompt"
        else
            fail "storing/reading a secret failed or hung (keyring prompt?)"
        fi
    fi
    in_session timeout 20 env SSH_AUTH_SOCK="/run/user/${ci_uid}/keyring/ssh" ssh-add -l &>/dev/null
    rc=$?
    # 0 = has keys, 1 = no keys: both mean the agent answered
    if ((rc == 0 || rc == 1)); then
        pass "SSH agent answers on \$XDG_RUNTIME_DIR/keyring/ssh"
    else
        fail "SSH agent at /run/user/${ci_uid}/keyring/ssh did not answer (ssh-add exit ${rc})"
    fi

    section "Desktop portal"
    scheme="$(user_env timeout 60 busctl --user call org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop \
        org.freedesktop.portal.Settings ReadOne ss org.freedesktop.appearance color-scheme 2>&1)"
    if [[ "${scheme}" == "v u 1" ]]; then
        pass "xdg-desktop-portal answers and reports dark mode"
    else
        fail "portal Settings color-scheme: expected 'v u 1' (prefer dark), got: ${scheme:-no answer}"
    fi

    section "Quickshell"
    qs_layers() { niri_json layers | jq -r '[.[] | select(.namespace != "wallpaper") | .namespace] | join(",")'; }
    if ((have_output)); then
        layers="$(qs_layers)"
        if [[ -n "${layers}" ]]; then
            pass "Quickshell has layer surfaces: ${layers}"
        else
            fail "Quickshell shows no layer surfaces (bar missing)"
        fi
        if in_session timeout 20 qs ipc call shell toggleHub &>/dev/null; then
            sleep 2
            after="$(qs_layers)"
            shot 04-hub
            if [[ "${after}" != "${layers}" ]]; then
                pass "Quickshell IPC opens the hub (layers: ${after})"
            else
                fail "qs ipc call shell toggleHub succeeded but no new surface appeared"
            fi
            in_session timeout 20 qs ipc call shell closeAll &>/dev/null
        else
            fail "Quickshell IPC (qs ipc call shell toggleHub) failed"
            in_session timeout 20 qs ipc call shell toggleHub 2>&1 | indent
        fi
    fi
    # Quickshell's output goes to niri.service's journal
    qml_errors="$(journalctl -b --no-pager -o cat _SYSTEMD_USER_UNIT=niri.service _UID="${ci_uid}" 2>/dev/null |
        grep -E 'ReferenceError|TypeError|SyntaxError|is not a type|is not installed|Cannot assign|Unable to assign|ERROR' |
        grep -v '^ *$' | head -n 20)"
    if [[ -z "${qml_errors}" ]]; then
        pass "no QML errors in Quickshell's log"
    else
        fail "Quickshell logged errors:"
        echo "${qml_errors}" | indent
    fi

    section "Apps"
    if ((have_output)); then
        in_session niri msg action spawn -- ghostty &>/dev/null
        has_ghostty() { niri_json windows | jq -e 'any(.[]; (.app_id // "") | test("ghostty"; "i"))'; }
        if wait_for 30 has_ghostty; then
            pass "Ghostty opens a window"
            sleep 2
            shot 05-terminal
            pkill -u "${CI_USER}" -x ghostty
        else
            fail "Ghostty did not open a window within 30s"
        fi
    fi
else
    section "Session"
    skip "session checks skipped: the password login did not start a niri session"
fi
