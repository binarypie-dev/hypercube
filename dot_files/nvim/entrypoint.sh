#!/usr/bin/bash
set -e

# Ensure the baked toolchains and AI CLIs are on PATH regardless of how the
# container was invoked. Claude Code and Antigravity install under $HOME/.local
# (/root, persisted in the home volume); codex/gh and the dev toolchain live
# under the linuxbrew home (image layers).
export PATH="$HOME/.local/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/home/linuxbrew/.npm-global/bin:/home/linuxbrew/go/bin:/home/linuxbrew/.cargo/bin:$PATH"

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
