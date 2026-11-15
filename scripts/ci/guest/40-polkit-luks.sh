#!/usr/bin/env bash
# Stage 4: admin password prompts (polkit) and the lock screen.
#
# The LUKS check reproduces the original niri bug: unlocking an encrypted
# system drive goes through udisks, which asks polkit, which needs the
# session's polkit agent to show a password dialog. Without a working agent
# udisksctl just fails with "Not authorized".
# Sourced after 30-session.sh.

# Typing: a virtual *kernel* keyboard (uinput). niri sees it through
# libinput exactly like a USB keyboard being plugged in, so keys go through
# the normal keymap and focus handling. (wtype's virtual-keyboard protocol
# was tried first: text arrived, but Enter never registered in GTK or
# swaylock.) Needs only python3 and /dev/uinput, both in the image.
cat > /var/tmp/ci-type.py <<'PY'
"""Type text (plus Enter) on a temporary uinput keyboard. US layout."""
import fcntl, os, struct, sys, time

UI_SET_EVBIT, UI_SET_KEYBIT = 0x40045564, 0x40045565
UI_DEV_SETUP, UI_DEV_CREATE, UI_DEV_DESTROY = 0x405C5503, 0x5501, 0x5502
EV_SYN, EV_KEY, SYN_REPORT = 0, 1, 0
KEY_ENTER, KEY_LEFTSHIFT, KEY_MINUS, KEY_SPACE = 28, 42, 12, 57
LETTERS = dict(zip("qwertyuiop", range(16, 26)))
LETTERS.update(zip("asdfghjkl", range(30, 39)))
LETTERS.update(zip("zxcvbnm", range(44, 51)))
DIGITS = dict(zip("1234567890", range(2, 12)))

def keycode(ch):
    """(keycode, shift) for a character on a US keyboard."""
    if ch.lower() in LETTERS:
        return LETTERS[ch.lower()], ch.isupper()
    if ch in DIGITS:
        return DIGITS[ch], False
    if ch == "-":
        return KEY_MINUS, False
    if ch == "_":
        return KEY_MINUS, True
    if ch == " ":
        return KEY_SPACE, False
    raise SystemExit(f"ci-type: can't type {ch!r}")

fd = os.open("/dev/uinput", os.O_WRONLY | os.O_NONBLOCK)
fcntl.ioctl(fd, UI_SET_EVBIT, EV_KEY)
for code in range(1, 128):
    fcntl.ioctl(fd, UI_SET_KEYBIT, code)
# struct uinput_setup: input_id (bustype=USB, vendor, product, version), name, ff_effects_max
fcntl.ioctl(fd, UI_DEV_SETUP, struct.pack("HHHH80sI", 0x03, 0x1D6B, 0x0104, 1, b"hypercube-ci keyboard", 0))
fcntl.ioctl(fd, UI_DEV_CREATE)
time.sleep(2)  # let udev/libinput/niri pick up the new keyboard

def emit(type_, code, value):
    os.write(fd, struct.pack("llHHi", 0, 0, type_, code, value))

def tap(code, shift=False):
    if shift:
        emit(EV_KEY, KEY_LEFTSHIFT, 1)
    emit(EV_KEY, code, 1); emit(EV_SYN, SYN_REPORT, 0)
    emit(EV_KEY, code, 0); emit(EV_SYN, SYN_REPORT, 0)
    if shift:
        emit(EV_KEY, KEY_LEFTSHIFT, 0); emit(EV_SYN, SYN_REPORT, 0)
    time.sleep(0.03)

for ch in sys.argv[1]:
    tap(*keycode(ch))
time.sleep(0.3)
tap(KEY_ENTER)
time.sleep(0.5)
fcntl.ioctl(fd, UI_DEV_DESTROY)
os.close(fd)
PY
have_typing=0
type_password() { python3 /var/tmp/ci-type.py "${CI_PASSWORD}"; }

if ((session_up)) && ((have_output)); then
    section "Typing (virtual keyboard)"
    if [[ -c /dev/uinput ]] || modprobe uinput 2>/dev/null && [[ -c /dev/uinput ]]; then
        have_typing=1
        echo "    /dev/uinput available; the password will be typed into dialogs"
    else
        skip "no /dev/uinput in the VM; dialogs are checked but not answered"
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
        if ((have_typing)); then
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
        if ((have_typing)); then
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
