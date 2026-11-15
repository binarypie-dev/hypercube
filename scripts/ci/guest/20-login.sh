#!/usr/bin/env bash
# Stage 2: the greeter, then a real password login.
#
# greetd's initial_session (autologin) skips authentication, so it can't show
# that PAM, the password and the keyring work. Instead a tiny scripted
# greeter speaks greetd's IPC protocol, the same one hypercube-greeter uses,
# and logs the test user in with their password: greetd -> PAM
# (pam_gnome_keyring) -> logind -> niri-session -> niri.service. The only
# part not exercised is hypercube-greeter's own TUI, which is screenshotted.
# Sourced after 00-lib.sh and 10-system.sh.

# Wayland socket name (e.g. wayland-0) a uid's compositor is serving, if any.
wayland_display_of() {
    local sock
    for sock in /run/user/"$1"/wayland-*; do
        [[ -S "${sock}" ]] && { basename "${sock}"; return 0; }
    done
    return 1
}

section "Greeter screens"
# First boot: onboarding runs as root under cage (initial_session).
if onboard_display="$(wayland_display_of 0)"; then
    screenshot 01-onboarding 0 "${onboard_display}"
fi
# greetd remembers initial_session already ran this boot (/run/greetd.run),
# so a restart brings up the normal greeter.
systemctl restart greetd.service
greeter_uid="$(id -u greeter 2>/dev/null || echo)"
if wait_for 60 pgrep -u greeter -f hypercube-greeter; then
    pass "hypercube-greeter is running after onboarding"
    sleep 3 # let it draw
    if [[ -n "${greeter_uid}" ]] && greeter_display="$(wayland_display_of "${greeter_uid}")"; then
        screenshot 02-greeter "${greeter_uid}" "${greeter_display}"
    fi
else
    fail "hypercube-greeter did not start after onboarding"
    journalctl -b --no-pager -n 30 -u greetd.service 2>&1 | indent
fi

section "Password login through greetd"
session_up=0
for tool in python3 grim jq; do
    command -v "${tool}" >/dev/null || fail "${tool} is not in the image; the login/session checks need it"
done
if ! id "${CI_USER}" &>/dev/null; then
    # wheel: polkit's admin rules then ask for the user's own password, as on
    # a real install where the first user is an admin.
    useradd -m -G wheel "${CI_USER}"
fi
echo "${CI_USER}:${CI_PASSWORD}" | chpasswd
ci_uid="$(id -u "${CI_USER}")"

# The scripted greeter. greetd's IPC: a native-endian u32 length, then JSON.
install -d -m 0755 /etc/greetd
printf '%s\n%s\n' "${CI_USER}" "${CI_PASSWORD}" > /etc/greetd/ci-login
chown root:greeter /etc/greetd/ci-login
chmod 0640 /etc/greetd/ci-login
cat > /etc/greetd/ci-greeter.py <<'PY'
import json, os, socket, struct, sys

log = open("/var/tmp/ci-greeter.log", "a", buffering=1)
user, password = open("/etc/greetd/ci-login").read().split("\n")[:2]
sock = socket.socket(socket.AF_UNIX)
sock.connect(os.environ["GREETD_SOCK"])

def recv_exact(n):
    buf = b""
    while len(buf) < n:
        chunk = sock.recv(n - len(buf))
        if not chunk:
            raise EOFError("greetd closed the connection")
        buf += chunk
    return buf

def call(request):
    data = json.dumps(request).encode()
    sock.sendall(struct.pack("=I", len(data)) + data)
    (length,) = struct.unpack("=I", recv_exact(4))
    reply = json.loads(recv_exact(length))
    print(request["type"], "->", reply.get("type"), reply.get("auth_message_type", ""),
          reply.get("description", ""), file=log)
    return reply

reply = call({"type": "create_session", "username": user})
while reply["type"] == "auth_message":
    answer = password if reply["auth_message_type"] in ("secret", "visible") else None
    reply = call({"type": "post_auth_message_response", "response": answer})
if reply["type"] != "success":
    print("login failed:", reply, file=log)
    call({"type": "cancel_session"})
    sys.exit(1)
# Same command and environment hypercube-greeter uses for niri.desktop
reply = call({"type": "start_session", "cmd": ["niri-session"],
              "env": ["XDG_SESSION_TYPE=wayland", "XDG_CURRENT_DESKTOP=niri"]})
sys.exit(0 if reply["type"] == "success" else 1)
PY
chmod 0644 /etc/greetd/ci-greeter.py
rm -f /var/tmp/ci-greeter.log

cp /etc/greetd/config.toml /etc/greetd/config.toml.ci-backup
cat > /etc/greetd/config.toml <<'GREETD'
[terminal]
vt = 1

[default_session]
command = "python3 /etc/greetd/ci-greeter.py"
user = "greeter"
GREETD
systemctl restart greetd.service

# Talk to the test user's systemd over its own bus. (`systemctl --user -M
# user@` would open a new PAM login session on every poll.) Fails quietly
# until the user is logged in and their manager is up.
user_env() {
    runuser -u "${CI_USER}" -- env \
        XDG_RUNTIME_DIR="/run/user/${ci_uid}" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${ci_uid}/bus" \
        "$@"
}
ci_user_systemctl() { user_env systemctl --user "$@"; }

if wait_for "${NIRI_TIMEOUT}" ci_user_systemctl is-active --quiet niri.service; then
    session_up=1
    pass "password login through greetd started niri.service for ${CI_USER}"
    session_type="$(loginctl show-user "${CI_USER}" -p Display --value 2>/dev/null)"
    [[ -n "${session_type}" ]] &&
        echo "    logind session: ${session_type} ($(loginctl show-session "${session_type}" -p Type -p Class -p Active --value 2>/dev/null | paste -sd' '))"
else
    fail "logging in ${CI_USER} with a password did not start niri.service within ${NIRI_TIMEOUT}s"
    echo "    --- scripted greeter"
    indent < /var/tmp/ci-greeter.log 2>/dev/null
    echo "    --- greetd"
    journalctl -b --no-pager -n 40 -u greetd.service 2>&1 | indent
    echo "    --- ${CI_USER}"
    journalctl -b --no-pager -n 80 _UID="${ci_uid}" 2>&1 | indent
fi
mv /etc/greetd/config.toml.ci-backup /etc/greetd/config.toml
