pragma Singleton

import QtQuick

// Icon mappings using Nerd Font icons
QtObject {
    id: root

    // Nerd Font icon codes
    readonly property var icons: ({
        // System
        settings: "\uf013",      //
        power: "\uf011",         //
        restart: "\uf01e",       //
        logout: "\uf2f5",        //
        lock: "\uf023",          //
        sleep: "\uf186",         //

        // Audio
        volumeHigh: "\uf028",    //
        volumeMedium: "\uf027",  //
        volumeLow: "\uf026",     //
        volumeMute: "\uf6a9",    //
        volumeOff: "\uf6a9",     // (alias for mute)
        mic: "\uf130",           //
        micOff: "\uf131",        //
        headphones: "\uf025",    //
        speaker: "\uf028",       //

        // Brightness
        brightnessHigh: "\uf185", //
        brightnessMedium: "\uf111", //
        brightnessLow: "\uf0eb",  //

        // Network
        wifi: "\uf1eb",          //
        wifiOff: "\uf1eb",       //  (with color change)
        wifiWeak: "\uf1eb",      //
        wifiMedium: "\uf1eb",    //
        wifiStrong: "\uf1eb",    //
        ethernet: "\uf6ff",      //
        ethernetOff: "\uf6ff",   //
        vpn: "\uf084",           //
        airplane: "\uf072",      //

        // Bluetooth
        bluetooth: "\uf294",     //
        bluetoothOff: "\uf294",  //
        bluetoothConnected: "\uf294", //
        bluetoothSearching: "\uf294", //

        // Battery
        battery: "\uf240",       //
        battery90: "\uf241",     //
        battery80: "\uf241",     //
        battery60: "\uf242",     //
        battery40: "\uf243",     //
        battery20: "\uf244",     //
        battery10: "\uf244",     //
        batteryEmpty: "\uf244",  //
        batteryCharging: "\uf0e7", //
        batteryAlert: "\uf071",  //

        // Notifications
        notification: "\uf0f3",  //
        notificationOff: "\uf1f6", //
        notificationActive: "\uf0f3", //
        notificationNone: "\uf0a2", //
        doNotDisturb: "\uf05e",  //

        // Privacy
        camera: "\uf03d",        //
        cameraOff: "\uf03d",     //
        screenShare: "\uf108",   //
        screenShareOff: "\uf108", //

        // Time & Calendar
        clock: "\uf017",         //
        calendar: "\uf073",      //
        today: "\uf073",         //
        event: "\uf073",         //
        alarm: "\uf0f3",         //
        timer: "\uf2f2",         //

        // Weather
        sunny: "\uf185",         //
        partlyCloudy: "\uf6c4",  //
        cloudy: "\uf0c2",        //
        rain: "\uf043",          //
        heavyRain: "\uf0e9",     //
        snow: "\uf2dc",          //
        fog: "\uf75f",           //
        wind: "\uf72e",          //
        night: "\uf186",         //
        nightCloudy: "\uf6c3",   //

        // Navigation
        menu: "\uf0c9",          //
        close: "\uf00d",         //
        back: "\uf060",          //
        forward: "\uf061",       //
        up: "\uf062",            //
        down: "\uf063",          //
        expand: "\uf078",        //
        collapse: "\uf077",      //
        search: "\uf002",        //
        filter: "\uf0b0",        //

        // Actions
        add: "\uf067",           //
        remove: "\uf068",        //
        delete: "\uf1f8",        //
        edit: "\uf044",          //
        copy: "\uf0c5",          //
        paste: "\uf0ea",         //
        refresh: "\uf021",       //
        check: "\uf00c",         //
        checkCircle: "\uf058",   //
        error: "\uf057",         //
        warning: "\uf071",       //
        info: "\uf05a",          //
        help: "\uf059",          //

        // Apps & Categories
        apps: "\uf009",          //
        grid: "\uf00a",          //
        list: "\uf03a",          //
        folder: "\uf07b",        //
        file: "\uf15b",          //
        image: "\uf03e",         //
        video: "\uf03d",         //
        music: "\uf001",         //
        download: "\uf019",      //
        upload: "\uf093",        //

        // User & Account
        person: "\uf007",        //
        personAdd: "\uf234",     //
        group: "\uf0c0",         //
        account: "\uf2bd",       //

        // Media controls
        play: "\uf04b",          //
        pause: "\uf04c",         //
        stop: "\uf04d",          //
        skipPrevious: "\uf048",  //
        skipNext: "\uf051",      //
        shuffle: "\uf074",       //
        repeat: "\uf01e",        //
        repeatOne: "\uf01e",     //

        // Misc
        star: "\uf005",          //
        starOutline: "\uf006",   //
        heart: "\uf004",         //
        heartOutline: "\uf08a",  //
        pin: "\uf08d",           //
        link: "\uf0c1",          //
        code: "\uf121",          //
        terminal: "\uf120",      //
        update: "\uf021",        //
        sync: "\uf021"           //
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
