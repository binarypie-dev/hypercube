# Hypercube bash/sh PATH setup
#
# Fish is the default Hypercube shell. When bash (or another POSIX shell) is
# launched without inheriting a full PATH, it can come up missing the standard
# system directories — /usr/bin, /bin, /usr/sbin, /sbin, etc. That is where
# system tools like podman live (/usr/bin/podman), so the ai-dev `claude`/`agy`
# wrapper scripts in ~/.local/bin failed: they exec `podman`, which was not
# resolvable on a stripped-down bash PATH.
#
# This file guarantees the default system directories are on PATH for sh/bash,
# and also mirrors the user PATH additions from /etc/fish/config.fish so both
# shells resolve the same locations. It is sourced by login shells via
# /etc/profile and by interactive non-login shells via /etc/bashrc (Fedora
# sources /etc/profile.d/* in both cases).

# Append a directory to PATH only if it isn't already present (used for the
# system dirs, which must always exist regardless of inheritance).
__hypercube_append_path() {
    case ":${PATH}:" in
        *":$1:"*) ;;
        *) PATH="${PATH:+$PATH:}$1" ;;
    esac
}

# Prepend a directory to PATH only if it exists and isn't already present
# (used for the per-user dirs, which may not exist yet).
__hypercube_prepend_path() {
    case ":${PATH}:" in
        *":$1:"*) ;;
        *) [ -d "$1" ] && PATH="$1:${PATH}" ;;
    esac
}

# Default system directories. Guaranteed present even if PATH was inherited
# empty or minimal (e.g. a non-interactive shell spawned from a service or GUI).
__hypercube_append_path "/usr/local/sbin"
__hypercube_append_path "/usr/local/bin"
__hypercube_append_path "/usr/sbin"
__hypercube_append_path "/usr/bin"
__hypercube_append_path "/sbin"
__hypercube_append_path "/bin"

# Per-user directories, mirroring dot_files/fish/config.fish.
__hypercube_prepend_path "$HOME/go/bin"
__hypercube_prepend_path "$HOME/.cargo/bin"
__hypercube_prepend_path "$HOME/.npm-packages/bin"
__hypercube_prepend_path "$HOME/.local/bin"

export PATH

# Pick up cargo's environment (extra PATH/vars) when rustup is installed,
# matching dot_files/fish/conf.d/rustup.fish.
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

unset -f __hypercube_append_path __hypercube_prepend_path
