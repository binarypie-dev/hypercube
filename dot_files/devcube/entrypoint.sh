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
# In particular workmux opens a new worktree's interactive pane with
# get_default_shell() -> $SHELL (else /bin/sh): without this a fresh worktree
# drops into /bin/sh, bypassing fish + the baked WORKMUX_BACKEND/starship
# config. (PATH above puts the brew fish on PATH so command -v resolves it.)
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

# Refresh image-baked editor/shell/multiplexer config into the home volume on
# every start, so config updates ship with `podman pull` instead of forcing a
# volume wipe. Only these fully image-owned dirs are replaced; auth + state
# (~/.local, ~/.claude, ~/.cache, plugin downloads + lazy-lock, shell history,
# zellij session serialization) live elsewhere on the volume and are untouched.
# rm -rf + cp -a (not rsync, which isn't installed) so files removed from the
# image also drop from the dir. The personal nvim override (~/.config/hypercube/
# nvim) is a different dir and is never touched.
config_src="/usr/share/hypercube/config"
for c in nvim fish zellij workmux; do
    src="$config_src/$c"
    dest="$HOME/.config/$c"
    [ -d "$src" ] || continue
    mkdir -p "$HOME/.config"
    # fish writes its universal variables (set -U, e.g. fish_user_paths/colors)
    # to $dest/fish_variables -- that's runtime STATE, not baked config, so carry
    # it across the refresh rather than wiping it with the config dir.
    saved=""
    if [ "$c" = fish ] && [ -f "$dest/fish_variables" ]; then
        saved="$(mktemp)" && cp -a "$dest/fish_variables" "$saved"
    fi
    rm -rf "$dest"
    cp -a "$src" "$dest"
    if [ -n "$saved" ]; then
        cp -a "$saved" "$dest/fish_variables"
        rm -f "$saved"
    fi
done

if [ $# -eq 0 ]; then
    exec nvim
else
    exec "$@"
fi
