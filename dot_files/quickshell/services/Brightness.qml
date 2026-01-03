pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Screen brightness control via brightnessctl (laptop) or ddcutil (external monitors)
Singleton {
    id: root

    property real brightness: 1.0
    property int maxBrightness: 100
    property int currentBrightness: 100
    property string device: ""
    property bool available: false
    property string controlMethod: "none"  // "backlight", "ddc", "none"

    // Pending output for parsing
    property string pendingDetect: ""
    property string pendingBacklight: ""
    property string pendingDdc: ""

    Component.onCompleted: {
        detectMethod.running = true
    }

    // Detect which control method is available
    Process {
        id: detectMethod
        command: ["sh", "-c", "if brightnessctl -l 2>/dev/null | grep -q backlight; then echo backlight; elif command -v ddcutil &>/dev/null && ddcutil detect --brief 2>/dev/null | grep -q Display; then echo ddc; else echo none; fi"]
        running: false

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data && data.trim()) {
                    root.pendingDetect = data.trim()
                }
            }
        }

        onExited: {
            const method = root.pendingDetect
            controlMethod = method
            available = (method !== "none")
            if (method === "backlight") {
                brightnessProcess.running = true
            } else if (method === "ddc") {
                ddcProcess.running = true
            }
            root.pendingDetect = ""
        }
    }

    // brightnessctl for laptop backlights
    Process {
        id: brightnessProcess
        command: ["brightnessctl", "-m"]
        running: false

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data && data.trim()) {
                    root.pendingBacklight = data.trim()
                }
            }
        }

        onExited: parseBacklightOutput()
    }

    function parseBacklightOutput() {
        const output = pendingBacklight
        pendingBacklight = ""
        if (!output) return

        // brightnessctl -m format: device,class,current,percentage,max
        const parts = output.split(",")
        if (parts.length >= 5) {
            device = parts[0]
            currentBrightness = parseInt(parts[2]) || 100
            maxBrightness = parseInt(parts[4]) || 100
            brightness = currentBrightness / maxBrightness
        }
    }

    // ddcutil for external monitors
    Process {
        id: ddcProcess
        command: ["ddcutil", "getvcp", "10", "--brief"]
        running: false

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data && data.trim()) {
                    root.pendingDdc = data.trim()
                }
            }
        }

        onExited: parseDdcOutput()
    }

    function parseDdcOutput() {
        const output = pendingDdc
        pendingDdc = ""
        if (!output) return

        // ddcutil --brief format: VCP 10 C 75 100
        // VCP code, type, current, max
        const parts = output.split(/\s+/)
        if (parts.length >= 5) {
            currentBrightness = parseInt(parts[3]) || 100
            maxBrightness = parseInt(parts[4]) || 100
            brightness = currentBrightness / maxBrightness
        }
    }

    // Update timer
    Timer {
        interval: 5000  // Longer interval for DDC (slower)
        running: available
        repeat: true
        onTriggered: {
            if (controlMethod === "backlight") {
                brightnessProcess.running = true
            } else if (controlMethod === "ddc") {
                ddcProcess.running = true
            }
        }
    }

    // Brightness control process
    Process {
        id: brightnessSetProcess
        command: ["true"]
        onExited: {
            if (controlMethod === "backlight") {
                brightnessProcess.running = true
            } else if (controlMethod === "ddc") {
                ddcProcess.running = true
            }
        }
    }

    // Control functions
    function setBrightness(value) {
        const percent = Math.round(value * 100)
        if (controlMethod === "backlight") {
            brightnessSetProcess.command = ["brightnessctl", "set", percent + "%"]
        } else if (controlMethod === "ddc") {
            brightnessSetProcess.command = ["ddcutil", "setvcp", "10", String(percent)]
        } else {
            return
        }
        brightnessSetProcess.running = true
        brightness = value
    }

    function increase(step) {
        if (controlMethod === "backlight") {
            brightnessSetProcess.command = ["brightnessctl", "set", "+" + step + "%"]
        } else if (controlMethod === "ddc") {
            const newVal = Math.min(100, Math.round(brightness * 100) + step)
            brightnessSetProcess.command = ["ddcutil", "setvcp", "10", String(newVal)]
        } else {
            return
        }
        brightnessSetProcess.running = true
    }

    function decrease(step) {
        if (controlMethod === "backlight") {
            brightnessSetProcess.command = ["brightnessctl", "set", step + "%-"]
        } else if (controlMethod === "ddc") {
            const newVal = Math.max(0, Math.round(brightness * 100) - step)
            brightnessSetProcess.command = ["ddcutil", "setvcp", "10", String(newVal)]
        } else {
            return
        }
        brightnessSetProcess.running = true
    }

    // Brightness as percentage
    function brightnessPercent() {
        return Math.round(brightness * 100)
    }
}
