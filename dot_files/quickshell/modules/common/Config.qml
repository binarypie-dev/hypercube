pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Persistent JSON configuration system
Singleton {
    id: root

    // Configuration ready flag
    property bool ready: false

    // Configuration file path - fallback to ~/.config if XDG_CONFIG_HOME is not set
    readonly property string configDir: {
        const xdg = Quickshell.env("XDG_CONFIG_HOME")
        if (xdg && xdg !== "") return xdg + "/hypercube"
        const home = Quickshell.env("HOME")
        return home + "/.config/hypercube"
    }
    readonly property string configPath: configDir + "/shell.json"
    readonly property string defaultConfigPath: Qt.resolvedUrl("../../defaults/config.json")

    // Default values (used for comparison when saving)
    readonly property var defaults: ({
        appearance: {
            darkMode: true,
            accentColor: "blue",
            wallpaperTheming: false,
            panelOpacity: 0.85
        },
        fonts: {
            family: "JetBrains Mono",
            mono: "JetBrains Mono",
            size: 14
        },
        bar: {
            showWeather: true,
            showBattery: true,
            showNetwork: true,
            showTray: true,
            showClock: true,
            use24Hour: true
        },
        notifications: {
            timeout: 5000,
            sounds: true,
            dndSchedule: false,
            dndStart: "22:00",
            dndEnd: "08:00"
        },
        sidebar: {
            animations: true,
            width: 380
        },
        osd: {
            timeout: 1500,
            showValue: true
        },
        weather: {
            location: "",
            units: "metric",
            updateInterval: 900000
        },
        launcher: {
            maxResults: 50,
            showCategories: true
        }
    })

    // Appearance settings
    property bool darkMode: defaults.appearance.darkMode
    property string accentColor: defaults.appearance.accentColor
    property bool wallpaperTheming: defaults.appearance.wallpaperTheming
    property real panelOpacity: defaults.appearance.panelOpacity

    // Font settings
    property string fontFamily: defaults.fonts.family
    property string monoFontFamily: defaults.fonts.mono
    property int fontSize: defaults.fonts.size

    // Bar settings
    property bool showWeather: defaults.bar.showWeather
    property bool showBattery: defaults.bar.showBattery
    property bool showNetwork: defaults.bar.showNetwork
    property bool showTray: defaults.bar.showTray
    property bool showClock: defaults.bar.showClock
    property bool use24Hour: defaults.bar.use24Hour

    // Notification settings
    property int notificationTimeout: defaults.notifications.timeout
    property bool notificationSounds: defaults.notifications.sounds
    property bool doNotDisturbSchedule: defaults.notifications.dndSchedule
    property string doNotDisturbStart: defaults.notifications.dndStart
    property string doNotDisturbEnd: defaults.notifications.dndEnd

    // Sidebar settings
    property bool sidebarAnimations: defaults.sidebar.animations
    property int sidebarWidth: defaults.sidebar.width

    // OSD settings
    property int osdTimeout: defaults.osd.timeout
    property bool osdShowValue: defaults.osd.showValue

    // Weather settings
    property string weatherLocation: defaults.weather.location
    property string weatherUnits: defaults.weather.units
    property int weatherUpdateInterval: defaults.weather.updateInterval

    // Launcher settings
    property int launcherMaxResults: defaults.launcher.maxResults
    property bool launcherShowCategories: defaults.launcher.showCategories

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
                use24Hour = config.bar.use24Hour ?? use24Hour
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

    // Process to write config file
    Process {
        id: saveProcess
        running: false

        onExited: {
            console.log("Config: Saved to", root.configPath)
        }
    }

    // Helper to add non-default value to config object
    function addIfChanged(obj, section, key, currentValue, defaultValue) {
        if (currentValue !== defaultValue) {
            if (!obj[section]) obj[section] = {}
            obj[section][key] = currentValue
        }
    }

    // Save configuration to file - only writes values that differ from defaults
    function save() {
        const config = {}

        // Appearance
        addIfChanged(config, "appearance", "darkMode", darkMode, defaults.appearance.darkMode)
        addIfChanged(config, "appearance", "accentColor", accentColor, defaults.appearance.accentColor)
        addIfChanged(config, "appearance", "wallpaperTheming", wallpaperTheming, defaults.appearance.wallpaperTheming)
        addIfChanged(config, "appearance", "panelOpacity", panelOpacity, defaults.appearance.panelOpacity)

        // Fonts
        addIfChanged(config, "fonts", "family", fontFamily, defaults.fonts.family)
        addIfChanged(config, "fonts", "mono", monoFontFamily, defaults.fonts.mono)
        addIfChanged(config, "fonts", "size", fontSize, defaults.fonts.size)

        // Bar
        addIfChanged(config, "bar", "showWeather", showWeather, defaults.bar.showWeather)
        addIfChanged(config, "bar", "showBattery", showBattery, defaults.bar.showBattery)
        addIfChanged(config, "bar", "showNetwork", showNetwork, defaults.bar.showNetwork)
        addIfChanged(config, "bar", "showTray", showTray, defaults.bar.showTray)
        addIfChanged(config, "bar", "showClock", showClock, defaults.bar.showClock)
        addIfChanged(config, "bar", "use24Hour", use24Hour, defaults.bar.use24Hour)

        // Notifications
        addIfChanged(config, "notifications", "timeout", notificationTimeout, defaults.notifications.timeout)
        addIfChanged(config, "notifications", "sounds", notificationSounds, defaults.notifications.sounds)
        addIfChanged(config, "notifications", "dndSchedule", doNotDisturbSchedule, defaults.notifications.dndSchedule)
        addIfChanged(config, "notifications", "dndStart", doNotDisturbStart, defaults.notifications.dndStart)
        addIfChanged(config, "notifications", "dndEnd", doNotDisturbEnd, defaults.notifications.dndEnd)

        // Sidebar
        addIfChanged(config, "sidebar", "animations", sidebarAnimations, defaults.sidebar.animations)
        addIfChanged(config, "sidebar", "width", sidebarWidth, defaults.sidebar.width)

        // OSD
        addIfChanged(config, "osd", "timeout", osdTimeout, defaults.osd.timeout)
        addIfChanged(config, "osd", "showValue", osdShowValue, defaults.osd.showValue)

        // Weather
        addIfChanged(config, "weather", "location", weatherLocation, defaults.weather.location)
        addIfChanged(config, "weather", "units", weatherUnits, defaults.weather.units)
        addIfChanged(config, "weather", "updateInterval", weatherUpdateInterval, defaults.weather.updateInterval)

        // Launcher
        addIfChanged(config, "launcher", "maxResults", launcherMaxResults, defaults.launcher.maxResults)
        addIfChanged(config, "launcher", "showCategories", launcherShowCategories, defaults.launcher.showCategories)

        // Only write if there are changes
        if (Object.keys(config).length === 0) {
            console.log("Config: No changes from defaults, skipping save")
            return
        }

        const jsonContent = JSON.stringify(config, null, 2)
        saveProcess.command = ["sh", "-c", "mkdir -p '" + root.configDir + "' && cat > '" + root.configPath + "' << 'EOFCONFIG'\n" + jsonContent + "\nEOFCONFIG"]
        saveProcess.running = true
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
