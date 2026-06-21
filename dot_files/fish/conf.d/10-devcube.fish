# Inside the devcube container, pin workmux to the zellij backend.
#
# workmux has no backend key in its config.yaml -- it auto-detects a multiplexer
# from the environment ($ZELLIJ / $TMUX / ...) and otherwise falls back to tmux.
# This image ships zellij and NO tmux, so any `workmux` run where $ZELLIJ isn't
# set (e.g. from a `devc nvim` or `devc claude` shell) would reach for a tmux
# that doesn't exist. Forcing it here -- in root's shell config -- makes zellij
# the backend for every shell in the container.
#
# Gated on $DEVCUBE so this same fish config is a no-op on the host system.
if set -q DEVCUBE
    set -gx WORKMUX_BACKEND zellij
end
