pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Persistent JSON configuration system
Singleton {
    id: root

    // Configuration ready flag
    property bool ready: false

    // Configuration file path
    readonly property string configPath: Quickshell.env("XDG_CONFIG_HOME") + "/hypercube/shell.json"
    readonly property string defaultConfigPath: Qt.resolvedUrl("../../defaults/config.json")

    // Appearance settings
    property bool darkMode: true
    property string accentColor: "blue" // blue, green, purple, orange, red, cyan
    property bool wallpaperTheming: false
    property real panelOpacity: 0.85

    // Font settings
    property string fontFamily: "JetBrains Mono"
    property string monoFontFamily: "JetBrains Mono"
    property int fontSize: 14

    // Bar settings
    property bool showWeather: true
    property bool showBattery: true
    property bool showNetwork: true
    property bool showTray: true
    property bool showClock: true

    // Notification settings
    property int notificationTimeout: 5000
    property bool notificationSounds: true
    property bool doNotDisturbSchedule: false
    property string doNotDisturbStart: "22:00"
    property string doNotDisturbEnd: "08:00"

    // Sidebar settings
    property bool sidebarAnimations: true
    property int sidebarWidth: 380

    // OSD settings
    property int osdTimeout: 1500
    property bool osdShowValue: true

    // Weather settings
    property string weatherLocation: "" // Empty = auto-detect
    property string weatherUnits: "metric" // metric, imperial
    property int weatherUpdateInterval: 900000 // 15 minutes

    // Launcher settings
    property int launcherMaxResults: 50
    property bool launcherShowCategories: true

    // Check if config file exists and create if needed
    Process {
        id: configDirCheck
        command: ["sh", "-c", "mkdir -p \"$(dirname '" + root.configPath + "')\" && [ -f '" + root.configPath + "' ] && echo exists || echo missing"]
        running: true
        onExited: {
            if (stdout && stdout.trim() === "missing") {
                console.log("Config: No user config found, using defaults")
                root.ready = true
            } else {
                // File exists, load it
                configFile.reload()
            }
        }
    }

    // File watcher for config changes
    FileView {
        id: configFile
        path: root.configPath
        watchChanges: true
        blockLoading: true
        preload: false  // Don't preload - we check existence first

        onFileChanged: {
            reload()
        }

        onLoaded: {
            if (text()) {
                root.parseConfig(text())
            } else {
                root.ready = true
            }
        }
    }

    // Parse configuration from JSON
    function parseConfig(content) {
        if (!content || content.trim() === "") {
            console.log("Config: Empty config, using defaults")
            ready = true
            return
        }

        try {
            const config = JSON.parse(content)

            // Appearance
            if (config.appearance) {
                darkMode = config.appearance.darkMode ?? darkMode
                accentColor = config.appearance.accentColor ?? accentColor
                wallpaperTheming = config.appearance.wallpaperTheming ?? wallpaperTheming
                panelOpacity = config.appearance.panelOpacity ?? panelOpacity
            }

            // Fonts
            if (config.fonts) {
                fontFamily = config.fonts.family ?? fontFamily
                monoFontFamily = config.fonts.mono ?? monoFontFamily
                fontSize = config.fonts.size ?? fontSize
            }

            // Bar
            if (config.bar) {
                showWeather = config.bar.showWeather ?? showWeather
                showBattery = config.bar.showBattery ?? showBattery
                showNetwork = config.bar.showNetwork ?? showNetwork
                showTray = config.bar.showTray ?? showTray
                showClock = config.bar.showClock ?? showClock
            }

            // Notifications
            if (config.notifications) {
                notificationTimeout = config.notifications.timeout ?? notificationTimeout
                notificationSounds = config.notifications.sounds ?? notificationSounds
                doNotDisturbSchedule = config.notifications.dndSchedule ?? doNotDisturbSchedule
                doNotDisturbStart = config.notifications.dndStart ?? doNotDisturbStart
                doNotDisturbEnd = config.notifications.dndEnd ?? doNotDisturbEnd
            }

            // Sidebar
            if (config.sidebar) {
                sidebarAnimations = config.sidebar.animations ?? sidebarAnimations
                sidebarWidth = config.sidebar.width ?? sidebarWidth
            }

            // OSD
            if (config.osd) {
                osdTimeout = config.osd.timeout ?? osdTimeout
                osdShowValue = config.osd.showValue ?? osdShowValue
            }

            // Weather
            if (config.weather) {
                weatherLocation = config.weather.location ?? weatherLocation
                weatherUnits = config.weather.units ?? weatherUnits
                weatherUpdateInterval = config.weather.updateInterval ?? weatherUpdateInterval
            }

            // Launcher
            if (config.launcher) {
                launcherMaxResults = config.launcher.maxResults ?? launcherMaxResults
                launcherShowCategories = config.launcher.showCategories ?? launcherShowCategories
            }

            console.log("Config: Loaded successfully")
            ready = true
        } catch (e) {
            console.error("Config: Failed to parse config:", e)
            ready = true // Use defaults
        }
    }

    // Save configuration to file
    function save() {
        const config = {
            appearance: {
                darkMode: darkMode,
                accentColor: accentColor,
                wallpaperTheming: wallpaperTheming,
                panelOpacity: panelOpacity
            },
            fonts: {
                family: fontFamily,
                mono: monoFontFamily,
                size: fontSize
            },
            bar: {
                showWeather: showWeather,
                showBattery: showBattery,
                showNetwork: showNetwork,
                showTray: showTray,
                showClock: showClock
            },
            notifications: {
                timeout: notificationTimeout,
                sounds: notificationSounds,
                dndSchedule: doNotDisturbSchedule,
                dndStart: doNotDisturbStart,
                dndEnd: doNotDisturbEnd
            },
            sidebar: {
                animations: sidebarAnimations,
                width: sidebarWidth
            },
            osd: {
                timeout: osdTimeout,
                showValue: osdShowValue
            },
            weather: {
                location: weatherLocation,
                units: weatherUnits,
                updateInterval: weatherUpdateInterval
            },
            launcher: {
                maxResults: launcherMaxResults,
                showCategories: launcherShowCategories
            }
        }

        configFile.setText(JSON.stringify(config, null, 2))
    }

    // Load configuration
    function load() {
        // Config file will be loaded automatically via preload
        // If already loaded, parse immediately
        if (configFile.loaded) {
            const content = configFile.text()
            if (content && content.trim() !== "") {
                parseConfig(content)
            } else {
                console.log("Config: No config file found, using defaults")
                ready = true
            }
        } else {
            // Will be parsed when onLoaded fires
            console.log("Config: Waiting for config file to load...")
        }
    }

    // Set a nested value and save
    function setValue(key, value) {
        const parts = key.split(".")
        if (parts.length === 1) {
            root[key] = value
        } else {
            // Handle nested keys like "appearance.darkMode"
            root[parts[1]] = value
        }
        save()
    }
}
