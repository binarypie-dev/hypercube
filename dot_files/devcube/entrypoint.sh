#!/usr/bin/bash
set -e

# Ensure the baked toolchains and AI CLIs are on PATH regardless of how the
# container was invoked. Claude Code and Antigravity install under $HOME/.local
# (/root, persisted in the home volume); codex/gh and the dev toolchain live
# under the linuxbrew home (image layers).
export PATH="$HOME/.local/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/home/linuxbrew/.npm-global/bin:/home/linuxbrew/go/bin:/home/linuxbrew/.cargo/bin:$PATH"

# Pin SHELL to fish so anything that spawns "the default shell" lands in fish,
# not the /bin/sh fallback. usermod makes fish root's login shell in
# /etc/passwd, but podman never exports $SHELL, so tools that read it miss it.
# Any interactive pane that reads $SHELL (else /bin/sh) -- e.g. the workbox
# workspace's shell pane -- would otherwise drop into /bin/sh, bypassing fish +
# the baked starship config. (PATH above puts the brew fish on PATH so command -v
# resolves it.)
if fish_bin="$(command -v fish 2>/dev/null)"; then
    export SHELL="$fish_bin"
fi

# Make sure TERM resolves inside the container. The host usually runs Ghostty
# (TERM=xterm-ghostty); that terminfo is baked into the image. Fall back to a
# known-good TERM if an unknown/empty value is propagated so TUIs don't emit
# raw escape sequences.
if [ -z "${TERM:-}" ] || ! infocmp "$TERM" >/dev/null 2>&1; then
    export TERM=xterm-256color
fi

if [ $# -eq 0 ]; then
    exec nvim
else
    exec "$@"
fi
