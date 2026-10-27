#!/bin/bash
# Migration: Move users' Hyprland stub config from hyprlang to Lua
#
# Hyprland 0.55+ prefers hyprland.lua anywhere on the config search path over
# hyprland.conf, and the system default is now hyprland.lua. Existing users
# still have the old ~/.config/hypr/hyprland.conf stub, which sources a file
# that no longer exists and is ignored in favour of the system hyprland.lua.
#
# For each user with a hyprland.conf but no hyprland.lua, write the new Lua
# stub. Any customizations they added to the old stub are carried over as
# comments so they can be ported by hand. hyprland.conf is left in place.

set -euo pipefail

SYSTEM_CONFIG="/usr/share/hypercube/config/hypr/hyprland.lua"

[[ -f "$SYSTEM_CONFIG" ]] || exit 0

while IFS=: read -r user _ uid gid _ home _; do
    [[ "$uid" -ge 1000 && "$uid" -lt 60000 ]] || continue

    hypr_dir="$home/.config/hypr"
    old="$hypr_dir/hyprland.conf"
    new="$hypr_dir/hyprland.lua"

    # Don't follow symlinks into places we shouldn't write (e.g. dotfile repos)
    [[ -f "$old" && ! -L "$old" && ! -L "$hypr_dir" ]] || continue
    [[ -e "$new" || -L "$new" ]] && continue

    echo "Migrating Hyprland config for $user to Lua..."

    # Everything the user wrote besides the stock stub lines
    custom=$(grep -vE '^\s*(#|$)|^\s*source\s*=\s*/usr/share/hypercube/config/hypr/hyprland\.conf\s*$' "$old" || true)

    tmp=$(mktemp)
    cat >"$tmp" <<EOF
-- Hypercube Hyprland Configuration
-- System defaults are required below. Add your customizations after this line.
-- Settings defined after the require will override the defaults.
-- To replace defaults entirely, remove or comment out the require line.

require("$SYSTEM_CONFIG")

-- Your customizations below:

EOF

    if [[ -n "$custom" ]]; then
        {
            echo "-- Migrated from hyprland.conf: Hyprland now uses Lua, so these"
            echo "-- hyprlang lines are inactive. Port them to Lua to re-enable them."
            echo "-- See https://wiki.hypr.land/Configuring/Start/"
            echo "-- ${custom//$'\n'/$'\n'-- }"
        } >>"$tmp"
    fi

    install -m 0644 -o "$uid" -g "$gid" "$tmp" "$new"
    rm -f "$tmp"

    luarc="/usr/share/hypercube/config/hypr/.luarc.json"
    if [[ -f "$luarc" && ! -e "$hypr_dir/.luarc.json" ]]; then
        install -m 0644 -o "$uid" -g "$gid" "$luarc" "$hypr_dir/.luarc.json"
    fi
done < <(getent passwd)

echo "Hyprland user config migration complete"
