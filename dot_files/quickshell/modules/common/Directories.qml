pragma Singleton

import QtQuick
import Quickshell

// XDG and application directory paths
QtObject {
    id: root

    // XDG Base directories
    readonly property string home: Quickshell.env("HOME") || "/home"
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")
    readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || (home + "/.local/share")
    readonly property string cacheHome: Quickshell.env("XDG_CACHE_HOME") || (home + "/.cache")
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")
    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || ("/run/user/" + Quickshell.env("UID"))

    // Application-specific directories
    readonly property string hypercubeConfig: configHome + "/hypercube"
    readonly property string hypercubeData: dataHome + "/hypercube"
    readonly property string hypercubeCache: cacheHome + "/hypercube"
    readonly property string hypercubeState: stateHome + "/hypercube"

    // Hyprland directories
    readonly property string hyprlandConfig: configHome + "/hypr"
    readonly property string hyprlandSocket: runtimeDir + "/hypr"

    // Common application directories
    readonly property string applicationsUser: dataHome + "/applications"
    readonly property string applicationsSystem: "/usr/share/applications"
    readonly property string iconsUser: dataHome + "/icons"
    readonly property string iconsSystem: "/usr/share/icons"

    // Wallpaper directories
    readonly property string wallpapersUser: dataHome + "/wallpapers"
    readonly property string wallpapersSystem: "/usr/share/wallpapers"
    readonly property string picturesDir: Quickshell.env("XDG_PICTURES_DIR") || (home + "/Pictures")

    // Screenshots directory
    readonly property string screenshotsDir: picturesDir + "/Screenshots"

    // Quickshell directories
    readonly property string quickshellConfig: configHome + "/quickshell"
    readonly property string quickshellData: dataHome + "/quickshell"

    // Helper to check if a path exists (would need Process to implement)
    function exists(path: string): bool {
        // This is a placeholder - actual implementation would use Process
        return true
    }

    // Helper to ensure directory exists
    function ensureDir(path: string): bool {
        // This is a placeholder - actual implementation would use Process
        return true
    }
}
