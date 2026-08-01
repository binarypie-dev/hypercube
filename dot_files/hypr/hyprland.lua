-- #######################################################################################
-- HYPRLAND CONFIG - Tokyo Night Theme with Vim-like Keybindings
-- #######################################################################################
--
-- Tokyo Night Color Palette:
-- - Background: #1a1b26
-- - Foreground: #c0caf5
-- - Blue (accent): #7aa2f7
-- - Purple (accent): #bb9af7
-- - Cyan: #7dcfff
-- - Green: #9ece6a
-- - Red: #f7768e
-- - Border inactive: #414868
--
-- Keybindings:
-- - Vim-like navigation: SUPER + h/j/k/l (left/down/up/right)
-- - Move windows: SUPER + SHIFT + h/j/k/l
-- - Resize windows: SUPER + CTRL + h/j/k/l
-- - App launcher: SUPER + R (opens left sidebar with search)
-- - Quick settings: SUPER + N (opens right sidebar)
--
-- #######################################################################################

-- Since Hyprland 0.55, hyprlang (.conf) is deprecated in favor of Lua.
-- Refer to the wiki for more information.
-- https://wiki.hypr.land/Configuring/


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })


---------------------
---- MY PROGRAMS ----
---------------------

-- See https://wiki.hypr.land/Configuring/Basics/Variables/

-- Set programs that you use
local terminal    = "ghostty"
local fileManager = "files"
local menu        = "qs ipc call shell toggleSidebarLeft"


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
    -- Export the Wayland session environment to the systemd user manager and the
    -- D-Bus activation environment. Without this, D-Bus-activated services such as
    -- xdg-desktop-portal fail to start when Hyprland is launched directly (i.e. not
    -- via uwsm), breaking dark-mode detection, file pickers, and screen sharing.
    -- Runs first so the services started below inherit a populated environment.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE")

    -- Quickshell - Launcher, Notifications, OSD
    hl.exec_cmd("quickshell")

    -- Wallpaper
    hl.exec_cmd("hyprpaper -c /usr/share/hypercube/config/hypr/hyprpaper.conf")

    -- Idle / Lock
    hl.exec_cmd("hypridle -c /usr/share/hypercube/config/hypr/hypridle.conf")

    -- Hyprland Polkit Authentication Agent (for privilege escalation)
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    -- GNOME Keyring (for secrets management, SSH keys, and certificates)
    hl.exec_cmd("gnome-keyring-daemon --start")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

-- Desktop identity - lets xdg-desktop-portal select the Hyprland backend
-- (hyprland-portals.conf) and route the Settings/color-scheme interface.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")

-- XDG directories - required for quickshell and other apps to find Hypercube configs
hl.env("XDG_CONFIG_DIRS", "/etc/xdg:/usr/share/hypercube/config")
hl.env("XDG_DATA_DIRS", "/usr/local/share:/usr/share:/usr/share/hypercube/data")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- SSH agent socket from GNOME Keyring
hl.env("SSH_AUTH_SOCK", os.getenv("XDG_RUNTIME_DIR") .. "/keyring/ssh")


-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
-- Tokyo Night Theme Colors
hl.config({
    -- https://wiki.hypr.land/Configuring/Basics/Variables/#general
    general = {
        gaps_in  = 5,
        gaps_out = 5,

        border_size = 2,

        col = {
            -- Tokyo Night colors - active border uses accent blue/purple gradient
            active_border   = { colors = { "rgba(7aa2f7ee)", "rgba(bb9af7ee)" }, angle = 45 },
            inactive_border = "rgba(414868aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    -- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
    decoration = {
        rounding       = 0,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1b26ee)", -- Tokyo Night background
        },

        -- https://wiki.hypr.land/Configuring/Basics/Variables/#blur
        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    -- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
    animations = {
        enabled = true,
    },
})

-- Default curves, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/#curves
hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },    { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 },       { 1, 1 } } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },   { 0.75, 1 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 },    { 0.1, 1 } } })

-- Default animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, border_size = 0 })
-- hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, rounding = 0 })
-- hl.window_rule({ match = { float = false, workspace = "f[1]" },   border_size = 0 })
-- hl.window_rule({ match = { float = false, workspace = "f[1]" },   rounding = 0 })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#misc
hl.config({
    misc = {
        force_default_wallpaper = 0,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
    },
})


---------------
---- INPUT ----
---------------

-- https://wiki.hypr.land/Configuring/Basics/Variables/#input
hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        -- caps:ctrl_modifier - Caps Lock acts as Ctrl
        kb_options = "caps:ctrl_modifier",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

-- See https://wiki.hypr.land/Configuring/Basics/Binds/
local mainMod = "SUPER" -- Sets "Windows" key as main modifier

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" })) -- Fullscreen
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
-- hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("qs ipc call shell toggleSidebarLeft")) -- Removed - use SUPER+R instead
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call shell toggleSidebarRight")) -- Notifications/quick settings
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("qs ipc call shell closeAll"))      -- Close all panels
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())          -- dwindle
hl.bind(mainMod .. " + S", hl.dsp.layout("togglesplit"))    -- dwindle
hl.bind(mainMod .. " + CTRL + Escape", hl.dsp.exec_cmd("hyprlock")) -- Lock screen

-- Move focus with mainMod + vim keys (h/j/k/l)
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Move focus with mainMod + arrow keys (alternative)
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Move windows with vim keys (mainMod + SHIFT + h/j/k/l)
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

-- Resize windows with vim keys (mainMod + CTRL + h/j/k/l)
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.resize({ x = -50, y = 0,   relative = true }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.resize({ x = 50,  y = 0,   relative = true }))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.resize({ x = 0,   y = -50, relative = true }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.resize({ x = 0,   y = 50,  relative = true }))

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + T",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
-- Volume control with OSD
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd([[wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ && qs ipc call shell showOsdVolume "$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2}')"]]), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd([[wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%- && qs ipc call shell showOsdVolume "$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2}')"]]), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd([[wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && qs ipc call shell showOsdVolume "$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2}')"]]), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd([[wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && qs ipc call shell showOsdMic "$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED && echo true || echo false)"]]), { locked = true, repeating = true })

-- Brightness control with OSD
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd([[brightnessctl set 5%+ && qs ipc call shell showOsdBrightness "$(brightnessctl -m | cut -d, -f4 | tr -d '%' | awk '{print $1/100}')"]]), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd([[brightnessctl set 5%- && qs ipc call shell showOsdBrightness "$(brightnessctl -m | cut -d, -f4 | tr -d '%' | awk '{print $1/100}')"]]), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Screenshot with Gradia (Print Screen key)
hl.bind("Print", hl.dsp.exec_cmd("flatpak run be.alexandervanhee.gradia --screenshot=INTERACTIVE"))

-- App Switcher (Super+Tab to switch between windows across all workspaces)
hl.bind(mainMod .. " + Tab",         hl.dsp.exec_cmd("qs ipc call shell nextWindow"))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.exec_cmd("qs ipc call shell prevWindow"))


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/ for more
-- See https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/ for workspace rules

-- Example windowrule
-- hl.window_rule({ match = { class = "^(kitty)$", title = "^(kitty)$" }, float = true })

-- Ignore maximize requests from apps. You'll probably like this.
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Quickshell launcher layer rules
hl.layer_rule({ match = { namespace = "quickshell" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "quickshell" }, animation = "slide" })

-- App switcher layer rules
hl.layer_rule({ match = { namespace = "appswitcher" }, animation = "fade" })
