-- Hyprland Kiosk Mode Configuration
-- Used for desktop kiosk mode applications
-- - No keybindings (locked down)
-- - Single fullscreen application
-- - Exits when the application closes
--
-- Since Hyprland 0.55, hyprlang (.conf) is deprecated in favor of Lua.
--
-- Usage: Set KIOSK_CMD environment variable before launching
--   KIOSK_CMD="your-app" Hyprland -c /path/to/hyprland-kiosk.lua

------------------
---- MONITORS ----
------------------

-- Enable all monitors - kiosk app shows on primary, others show wallpaper
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    -- Wallpaper on all monitors
    hl.exec_cmd("hyprpaper -c /usr/share/hypercube/config/hypr/hyprpaper.conf")

    -- Launch the kiosk application from the KIOSK_CMD environment variable
    -- (exec_cmd runs via `sh -c`, so the variable is expanded by the shell)
    hl.exec_cmd("$KIOSK_CMD")

    -- Exit Hyprland when the last window closes
    hl.exec_cmd([[handle=$(hyprctl -j clients | jq -r '.[0].address // empty'); while [ -n "$handle" ]; do sleep 0.5; handle=$(hyprctl -j clients | jq -r '.[0].address // empty'); done; hyprctl dispatch 'hl.dsp.exit()']])
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 0,
        gaps_out = 0,
        border_size = 0,
        col = {
            active_border   = "rgba(00000000)",
            inactive_border = "rgba(00000000)",
        },
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding         = 0,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = false,
        },
        blur = {
            enabled = false,
        },
    },

    animations = {
        enabled = false,
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },
})

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

---------------------
---- KEYBINDINGS ----
---------------------

-- No keybindings - kiosk mode is locked down

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Force all windows to fullscreen
hl.window_rule({ name = "kiosk-fullscreen", match = { class = ".*" }, fullscreen = true })
hl.window_rule({ match = { class = "^$", title = "^$" }, no_focus = true })
