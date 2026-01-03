pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Power management service for power profiles and session actions
Singleton {
    id: root

    // Power profile support
    property bool profilesAvailable: false
    property string currentProfile: "balanced"  // performance, balanced, power-saver
    property var availableProfiles: []

    // Pending output buffer
    property string pendingProfileOutput: ""

    // Power profile query script
    readonly property string profileQueryScript: "
        if command -v powerprofilesctl &>/dev/null; then
            echo \"available=true\"
            PROFILES=$(powerprofilesctl list | grep -E '^\\s*(performance|balanced|power-saver):' | sed 's/:$//' | tr -d ' ' | tr '\\n' ',' | sed 's/,$//')
            echo \"profiles=$PROFILES\"
            CURRENT=$(powerprofilesctl get 2>/dev/null)
            echo \"current=$CURRENT\"
        else
            echo \"available=false\"
        fi
    "

    Process {
        id: profileProcess
        command: ["sh", "-c", root.profileQueryScript]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.parseProfileLine(data)
        }
    }

    function parseProfileLine(line) {
        if (!line || line.trim() === "") return

        const idx = line.indexOf("=")
        if (idx === -1) return

        const key = line.substring(0, idx).trim()
        const value = line.substring(idx + 1).trim()

        switch (key) {
            case "available":
                profilesAvailable = value === "true"
                break
            case "profiles":
                if (value) {
                    availableProfiles = value.split(",").filter(p => p)
                }
                break
            case "current":
                currentProfile = value || "balanced"
                break
        }
    }

    // Update timer for power profiles
    Timer {
        interval: 10000  // 10 seconds
        running: true
        repeat: true
        onTriggered: profileProcess.running = true
    }

    // Set power profile
    function setProfile(profile) {
        if (!profilesAvailable) return
        setProfileProcess.command = ["powerprofilesctl", "set", profile]
        setProfileProcess.running = true
        currentProfile = profile
    }

    Process {
        id: setProfileProcess
        command: ["true"]
        onExited: profileProcess.running = true
    }

    // Session actions
    function logout() {
        logoutProcess.running = true
    }

    Process {
        id: logoutProcess
        command: ["sh", "-c", "hyprctl dispatch exit || loginctl terminate-session $XDG_SESSION_ID"]
    }

    function lock() {
        lockProcess.running = true
    }

    Process {
        id: lockProcess
        command: ["hyprlock"]
    }

    function suspend() {
        suspendProcess.running = true
    }

    Process {
        id: suspendProcess
        command: ["systemctl", "suspend"]
    }

    function powerOff() {
        powerOffProcess.running = true
    }

    Process {
        id: powerOffProcess
        command: ["systemctl", "poweroff"]
    }

    function reboot() {
        rebootProcess.running = true
    }

    Process {
        id: rebootProcess
        command: ["systemctl", "reboot"]
    }

    // Profile display names
    function profileDisplayName(profile) {
        switch (profile) {
            case "performance": return "Performance"
            case "balanced": return "Balanced"
            case "power-saver": return "Power Saver"
            default: return profile
        }
    }

    // Profile icons
    function profileIcon(profile) {
        switch (profile) {
            case "performance": return "zap"
            case "balanced": return "gauge"
            case "power-saver": return "leaf"
            default: return "gauge"
        }
    }
}
