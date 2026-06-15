# Hypercube bash/sh PATH setup
#
# Fish is the default Hypercube shell and configures the user PATH in
# /etc/fish/config.fish (~/.local/bin, ~/.cargo/bin, etc). Bash and other
# POSIX shells don't read that config, so anything launched from them — such
# as the `claude`/`agy` wrapper scripts in ~/.local/bin, which exec `podman`
# — ended up with a stripped-down PATH and could not find those tools.
#
# This file mirrors the fish PATH additions for sh/bash so both shells resolve
# the same locations. It is sourced by login shells via /etc/profile and by
# interactive non-login shells via /etc/bashrc (Fedora sources /etc/profile.d/*).

# Prepend a directory to PATH only if it exists and isn't already present.
__hypercube_add_path() {
    case ":${PATH}:" in
        *":$1:"*) ;;
        *) [ -d "$1" ] && PATH="$1:${PATH}" ;;
    esac
}

__hypercube_add_path "$HOME/go/bin"
__hypercube_add_path "$HOME/.cargo/bin"
__hypercube_add_path "$HOME/.npm-packages/bin"
__hypercube_add_path "$HOME/.local/bin"

export PATH

# Pick up cargo's environment (extra PATH/vars) when rustup is installed,
# matching dot_files/fish/conf.d/rustup.fish.
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

unset -f __hypercube_add_path
