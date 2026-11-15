#!/usr/bin/env bash
# Stage 4: admin password prompts (polkit) and the lock screen.
#
# The LUKS check reproduces the original niri bug: unlocking an encrypted
# system drive goes through udisks, which asks polkit, which needs the
# session's polkit agent to show a password dialog. Without a working agent
# udisksctl just fails with "Not authorized".
# Sourced after 30-session.sh.

# wtype types into the focused window through the virtual-keyboard protocol.
# It isn't part of the image, so install it on this throwaway disk only: a
# transient writable /usr (bootc usr-overlay) that vanishes on reboot.
have_wtype=0
ensure_wtype() {
    command -v wtype >/dev/null && return 0
    bootc usr-overlay &>/dev/null || true
    timeout 300 dnf5 -y -q install wtype &>/dev/null || timeout 300 dnf -y -q install wtype &>/dev/null
    command -v wtype >/dev/null
}
# One wtype call for the text *and* Enter: each call is a new virtual
# keyboard with its own keymap, and GTK3 (the polkit dialog) ignored the
# Enter sent by a second one, leaving the typed password unsubmitted.
type_password() {
    in_session wtype -d 20 "${CI_PASSWORD}" -s 300 -k Return
}

if ((session_up)) && ((have_output)); then
    section "Typing (wtype)"
    if ensure_wtype; then
        have_wtype=1
        echo "    wtype available; the password will be typed into dialogs"
    else
        skip "wtype could not be installed in the VM (no network?); dialogs are checked but not answered"
    fi

    section "Polkit: unlock a LUKS drive"
    for tool in cryptsetup udisksctl losetup; do
        command -v "${tool}" >/dev/null || fail "${tool} is not in the image; the LUKS unlock check needs it"
    done
    luks_img=/var/tmp/ci-luks.img
    luks_key=/var/tmp/ci-luks.key
    printf '%s' "ci-luks-passphrase" > "${luks_key}"
    chmod 0644 "${luks_key}"
    truncate -s 64M "${luks_img}"
    cryptsetup luksFormat --batch-mode --type luks2 --pbkdf pbkdf2 --pbkdf-force-iterations 1000 \
        --key-file "${luks_key}" "${luks_img}"
    loopdev="$(losetup --find --show "${luks_img}")"
    udevadm settle
    echo "    encrypted device: ${loopdev} (set up by root, so udisks treats it as a system drive)"
    rm -f /var/tmp/ci-udisks.out /var/tmp/ci-udisks.rc

    # Started from niri like an app would be, so polkit ties the request to
    # the graphical session and its agent.
    in_session niri msg action spawn -- sh -c \
        "udisksctl unlock -b ${loopdev} --key-file ${luks_key} > /var/tmp/ci-udisks.out 2>&1; echo \$? > /var/tmp/ci-udisks.rc" \
        &>/dev/null

    polkit_window() {
        niri_json windows | jq -ce 'first(.[] | select(((.app_id // "") + " " + (.title // "")) | test("polkit|authenticat"; "i")))'
    }
    if wait_for 30 polkit_window; then
        pass "polkit agent shows a password dialog for the LUKS unlock"
        dialog="$(polkit_window)"
        echo "    window: $(jq -r '"\(.app_id) — \(.title) (focused: \(.is_focused))"' <<<"${dialog}")"
        sleep 2
        shot 06-polkit-dialog
        if ((have_wtype)); then
            # Make sure keystrokes go to the dialog, not whatever had focus
            in_session niri msg action focus-window --id "$(jq -r .id <<<"${dialog}")" &>/dev/null
            sleep 1
            type_password
            if wait_for 60 test -s /var/tmp/ci-udisks.rc; then
                rc="$(cat /var/tmp/ci-udisks.rc)"
                if [[ "${rc}" == "0" ]] && lsblk -nro TYPE "${loopdev}" | grep -qx crypt; then
                    pass "LUKS drive unlocked after typing the password into the dialog"
                    indent < /var/tmp/ci-udisks.out
                else
                    fail "udisksctl unlock failed after answering the dialog (exit ${rc})"
                    indent < /var/tmp/ci-udisks.out
                fi
            else
                fail "udisksctl did not finish within 60s of typing the password"
                shot 06b-polkit-after-typing
                echo "    --- focused window"
                niri_json focused-window | jq -r '"\(.app_id) — \(.title)"' 2>&1 | indent
                echo "    --- polkit (authentication results)"
                journalctl -b --no-pager -n 20 -u polkit.service 2>&1 | indent
                echo "    --- polkit agent"
                journalctl -b --no-pager -n 20 _UID="${ci_uid}" _COMM=polkit-mate-aut 2>&1 | indent
                journalctl -b --no-pager -n 10 _COMM=polkit-agent-he 2>&1 | indent
                echo "    --- udisksctl"
                indent < /var/tmp/ci-udisks.out 2>/dev/null
            fi
        fi
    else
        if [[ -s /var/tmp/ci-udisks.rc ]]; then
            fail "no polkit dialog appeared; udisksctl exited $(cat /var/tmp/ci-udisks.rc):"
            indent < /var/tmp/ci-udisks.out
        else
            fail "no polkit dialog appeared within 30s"
        fi
        echo "    --- windows"
        niri_json windows | jq -r '.[] | "\(.app_id) — \(.title)"' | indent
        echo "    --- polkit agent"
        ci_user_systemctl status --no-pager --lines=15 hypercube-polkit-agent.service 2>&1 | indent
        journalctl -b --no-pager -n 20 -u polkit.service 2>&1 | indent
        shot 06-polkit-missing
    fi
    pkill -u "${CI_USER}" -x udisksctl 2>/dev/null
    udisksctl lock -b "${loopdev}" &>/dev/null
    losetup -d "${loopdev}" 2>/dev/null

    section "Lock screen"
    session_id="$(loginctl show-user "${CI_USER}" -p Display --value 2>/dev/null)"
    # loginctl lock-session -> swayidle's lock handler -> swaylock
    loginctl lock-session "${session_id}"
    if wait_for 30 pgrep -u "${CI_USER}" -x swaylock; then
        pass "loginctl lock-session starts swaylock (via swayidle)"
        sleep 2
        shot 07-locked
        if ((have_wtype)); then
            type_password
            if wait_for 30 bash -c "! pgrep -u '${CI_USER}' -x swaylock"; then
                pass "swaylock unlocks with the login password"
                sleep 1
                shot 08-unlocked
            else
                fail "swaylock is still running 30s after typing the password"
                journalctl -b --no-pager -n 20 _COMM=swaylock 2>&1 | indent
            fi
        fi
    else
        fail "locking the session did not start swaylock"
        pgrep -a -u "${CI_USER}" swayidle | indent
    fi
elif ((session_up)); then
    section "Polkit and lock screen"
    skip "polkit dialog and lock screen checks need niri to have an output (VM_GPU=virgl)"
fi
