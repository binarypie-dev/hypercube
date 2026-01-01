pragma Singleton

import QtQuick

// Icon name mappings for Lucide SVG icons
// Icons are stored in assets/icons/ as SVG files
// Use with the Icon component: Common.Icon { name: Common.Icons.icons.settings }
QtObject {
    id: root

    readonly property var icons: ({
        // System
        settings: "settings",
        power: "power",
        restart: "refresh-cw",
        logout: "log-out",
        lock: "lock",
        sleep: "moon",

        // Audio
        volumeHigh: "volume-2",
        volumeMedium: "volume-1",
        volumeLow: "volume",
        volumeMute: "volume-x",
        volumeOff: "volume-x",
        mic: "mic",
        micOff: "mic-off",
        headphones: "headphones",
        speaker: "speaker",

        // Brightness
        brightnessHigh: "sun",
        brightnessMedium: "sun-medium",
        brightnessLow: "sun-dim",

        // Network
        wifi: "wifi",
        wifiOff: "wifi-off",
        wifiWeak: "wifi",
        wifiMedium: "wifi",
        wifiStrong: "wifi",
        ethernet: "ethernet-port",
        ethernetOff: "ethernet-port",
        vpn: "key",
        airplane: "plane",

        // Bluetooth
        bluetooth: "bluetooth",
        bluetoothOff: "bluetooth-off",
        bluetoothConnected: "bluetooth-connected",
        bluetoothSearching: "bluetooth-searching",

        // Battery
        battery: "battery-full",
        battery90: "battery-full",
        battery80: "battery-medium",
        battery60: "battery-medium",
        battery40: "battery-low",
        battery20: "battery-low",
        battery10: "battery-warning",
        batteryEmpty: "battery-warning",
        batteryCharging: "battery-charging",
        batteryAlert: "battery-warning",
        plug: "plug",

        // Power profiles
        zap: "zap",
        gauge: "gauge",
        leaf: "leaf",

        // Notifications
        notification: "bell",
        notificationOff: "bell-off",
        notificationActive: "bell-ring",
        notificationNone: "bell-minus",
        doNotDisturb: "bell-off",

        // Privacy
        camera: "camera",
        cameraOff: "camera-off",
        screenShare: "monitor",
        screenShareOff: "monitor-off",

        // Time & Calendar
        clock: "clock",
        calendar: "calendar",
        today: "calendar-days",
        event: "calendar-days",
        alarm: "alarm-clock",
        timer: "timer",

        // Weather
        sunny: "sun",
        partlyCloudy: "cloud-sun",
        cloudy: "cloud",
        rain: "cloud-rain",
        heavyRain: "cloud-lightning",
        snow: "cloud-snow",
        fog: "cloud-fog",
        wind: "wind",
        night: "moon",
        nightCloudy: "cloud-moon",

        // Navigation
        menu: "menu",
        close: "x",
        back: "arrow-left",
        forward: "arrow-right",
        up: "arrow-up",
        down: "arrow-down",
        expand: "chevron-down",
        collapse: "chevron-up",
        search: "search",
        filter: "filter",

        // Actions
        add: "plus",
        remove: "minus",
        delete: "trash-2",
        edit: "pencil",
        copy: "copy",
        paste: "clipboard-paste",
        refresh: "rotate-cw",
        check: "check",
        checkCircle: "check-circle",
        error: "x-circle",
        warning: "alert-triangle",
        info: "info",
        help: "help-circle",

        // Apps & Categories
        apps: "layout-grid",
        grid: "layout-grid",
        list: "list",
        folder: "folder",
        file: "file",
        image: "image",
        video: "video",
        music: "music",
        download: "download",
        upload: "upload",

        // User & Account
        person: "user",
        personAdd: "user-plus",
        group: "users",
        account: "circle-user",

        // Media controls
        play: "play",
        pause: "pause",
        stop: "square",
        skipPrevious: "skip-back",
        skipNext: "skip-forward",
        shuffle: "shuffle",
        repeat: "repeat",
        repeatOne: "repeat-1",

        // Location
        mapPin: "map-pin",

        // Misc
        thermometer: "thermometer",
        droplets: "droplets",
        eye: "eye",
        star: "star",
        starOutline: "star",
        heart: "heart",
        heartOutline: "heart",
        pin: "pin",
        link: "link",
        code: "code",
        terminal: "terminal",
        update: "refresh-cw",
        sync: "refresh-ccw"
    })

    // Get icon for battery level
    function batteryIcon(level, charging) {
        if (charging) return icons.batteryCharging
        if (level >= 90) return icons.battery
        if (level >= 80) return icons.battery90
        if (level >= 60) return icons.battery80
        if (level >= 40) return icons.battery60
        if (level >= 20) return icons.battery40
        if (level >= 10) return icons.battery20
        return icons.batteryEmpty
    }

    // Get icon for volume level
    function volumeIcon(level, muted) {
        if (muted) return icons.volumeMute
        if (level >= 66) return icons.volumeHigh
        if (level >= 33) return icons.volumeMedium
        return icons.volumeLow
    }

    // Get icon for brightness level
    function brightnessIcon(level) {
        if (level >= 66) return icons.brightnessHigh
        if (level >= 33) return icons.brightnessMedium
        return icons.brightnessLow
    }

    // Get icon for wifi strength
    function wifiIcon(strength, connected) {
        if (!connected) return icons.wifiOff
        return icons.wifi
    }

    // Get icon for weather condition
    function weatherIcon(condition, isNight) {
        if (!condition) return icons.cloudy
        const lc = condition.toLowerCase()
        if (lc.includes("clear") || lc.includes("sunny")) {
            return isNight ? icons.night : icons.sunny
        }
        if (lc.includes("partly") || lc.includes("few clouds")) {
            return isNight ? icons.nightCloudy : icons.partlyCloudy
        }
        if (lc.includes("cloud") || lc.includes("overcast")) return icons.cloudy
        if (lc.includes("thunder") || lc.includes("storm")) return icons.heavyRain
        if (lc.includes("rain") || lc.includes("drizzle")) return icons.rain
        if (lc.includes("snow") || lc.includes("sleet")) return icons.snow
        if (lc.includes("fog") || lc.includes("mist") || lc.includes("haze")) return icons.fog
        if (lc.includes("wind")) return icons.wind
        return icons.cloudy
    }
}
