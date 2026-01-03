pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../modules/common" as Common

Singleton {
    id: root

    property bool ready: false
    property bool loading: false
    property string error: ""

    // Current weather
    property string temperature: ""
    property string feelsLike: ""
    property string condition: ""
    property string description: ""
    property int humidity: 0
    property string windSpeed: ""
    property string windDirection: ""
    property string visibility: ""
    property string pressure: ""
    property string uvIndex: ""

    // Location
    property string location: ""
    property string region: ""
    property string country: ""

    // Day/night for icons
    property bool isNight: false

    // Icon based on condition
    property string icon: Common.Icons.weatherIcon(condition, isNight)

    // Pending output buffer
    property string pendingOutput: ""

    Process {
        id: weatherProcess
        command: ["curl", "-s", "--max-time", "10",
            "wttr.in/" + (Common.Config.weatherLocation || "") + "?format=j1"]

        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.pendingOutput = this.text
            }
        }

        onRunningChanged: {
            if (running) {
                root.pendingOutput = ""
            }
        }

        onExited: parseOutput()
    }

    // Retry count for failed requests
    property int retryCount: 0
    readonly property int maxRetries: 3

    function parseOutput() {
        loading = false

        const output = root.pendingOutput
        if (!output || output.trim() === "") {
            // Network might not be ready yet, retry silently
            if (retryCount < maxRetries) {
                retryCount++
                retryTimer.start()
            }
            // Don't show error, just stay in "not ready" state
            return
        }

        // Reset retry count on successful response
        retryCount = 0

        try {
            const data = JSON.parse(output)

            if (!data.current_condition || data.current_condition.length === 0) {
                // Invalid data, but don't show error - just not ready
                return
            }

            const current = data.current_condition[0]
            const area = data.nearest_area ? data.nearest_area[0] : null

            // Temperature
            const units = Common.Config.weatherUnits
            if (units === "imperial") {
                temperature = current.temp_F + "°F"
                feelsLike = current.FeelsLikeF + "°F"
                windSpeed = current.windspeedMiles + " mph"
                visibility = current.visibilityMiles + " mi"
            } else {
                temperature = current.temp_C + "°C"
                feelsLike = current.FeelsLikeC + "°C"
                windSpeed = current.windspeedKmph + " km/h"
                visibility = current.visibility + " km"
            }

            // Condition
            condition = current.weatherDesc && current.weatherDesc[0]
                ? current.weatherDesc[0].value
                : "Unknown"
            description = condition

            // Other data
            humidity = parseInt(current.humidity) || 0
            windDirection = current.winddir16Point || ""
            pressure = current.pressure + " mb"
            uvIndex = current.uvIndex || ""

            // Location
            if (area) {
                location = area.areaName && area.areaName[0]
                    ? area.areaName[0].value
                    : ""
                region = area.region && area.region[0]
                    ? area.region[0].value
                    : ""
                country = area.country && area.country[0]
                    ? area.country[0].value
                    : ""
            }

            // Check if it's night (simple check based on time)
            const now = new Date()
            const hour = now.getHours()
            isNight = hour < 6 || hour >= 20

            error = ""
            ready = true

        } catch (e) {
            // Parse error - don't show to user, just log
            console.error("Weather parse error:", e)
        }
    }

    // Retry timer for failed requests
    Timer {
        id: retryTimer
        interval: 5000  // 5 seconds between retries
        onTriggered: refresh()
    }

    function refresh() {
        if (loading) return
        loading = true
        weatherProcess.running = true
    }

    // Auto-refresh timer
    Timer {
        interval: Common.Config.weatherUpdateInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: refresh()
    }

    // Summary string for tooltip
    function summary(): string {
        if (!ready) return "Loading weather..."
        if (error) return "Weather unavailable"

        let parts = []
        parts.push(condition)
        parts.push("Feels like " + feelsLike)
        parts.push("Humidity " + humidity + "%")
        parts.push("Wind " + windSpeed + " " + windDirection)

        if (location) {
            parts.unshift(location)
        }

        return parts.join("\n")
    }
}
