# Refresh the image-baked nvim + zellij config into ~/.config on the host so the
# local `nvim` and `zellij` run preconfigured, sharing the same configuration
# that ships baked inside the devcube container.
#
# Hypercube bakes the dotfiles at the read-only /usr/share/hypercube/config, but
# neither nvim (no $XDG_CONFIG_DIRS for its init) nor zellij loads config from
# there, so a copy has to live in ~/.config. The staleness check + atomic replace
# live in /usr/libexec/hypercube/sync-local-config; this just runs it once per
# interactive login.
#
# Gated off $DEVCUBE: inside the devcube container the entrypoint already owns
# the sync (and the helper short-circuits there too, as a belt-and-suspenders).
if status is-interactive
    and not set -q DEVCUBE
    and test -x /usr/libexec/hypercube/sync-local-config
    /usr/libexec/hypercube/sync-local-config 2>/dev/null
end
