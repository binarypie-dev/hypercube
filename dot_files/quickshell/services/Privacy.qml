pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Monitors microphone and camera usage via PipeWire/PulseAudio
Singleton {
    id: root

    property bool micInUse: false
    property bool cameraInUse: false
    property bool screenShareInUse: false

    // List of apps using mic/camera
    property var micApps: []
    property var cameraApps: []

    // Privacy query script
    readonly property string privacyQueryScript: "
        # Check microphone usage via PipeWire
        if command -v pw-cli &>/dev/null; then
            STREAMS=$(pw-cli list-objects 2>/dev/null | grep -B10 'media.class = \"Stream/Input/Audio\"' | grep 'application.name' | cut -d'\"' -f2 | sort -u | tr '\\n' ',' | sed 's/,$//')
            if [ -n \"$STREAMS\" ]; then
                echo \"micInUse=true\"
                echo \"micApps=$STREAMS\"
            else
                echo \"micInUse=false\"
                echo \"micApps=\"
            fi
        elif command -v pactl &>/dev/null; then
            SOURCES=$(pactl list source-outputs 2>/dev/null | grep -c 'Source Output')
            if [ \"$SOURCES\" -gt 0 ]; then
                echo \"micInUse=true\"
                APPS=$(pactl list source-outputs 2>/dev/null | grep 'application.name' | cut -d'\"' -f2 | tr '\\n' ',')
                echo \"micApps=$APPS\"
            else
                echo \"micInUse=false\"
                echo \"micApps=\"
            fi
        else
            echo \"micInUse=false\"
            echo \"micApps=\"
        fi

        # Check camera usage via /dev/video*
        CAM_PROCS=\"\"
        for dev in /dev/video*; do
            if [ -c \"$dev\" ]; then
                PIDS=$(fuser \"$dev\" 2>/dev/null)
                for pid in $PIDS; do
                    if [ -n \"$pid\" ] && [ -f \"/proc/$pid/comm\" ]; then
                        PROC=$(cat /proc/$pid/comm 2>/dev/null)
                        if [ -n \"$PROC\" ]; then
                            CAM_PROCS=\"$CAM_PROCS$PROC,\"
                        fi
                    fi
                done
            fi
        done
        CAM_PROCS=$(echo \"$CAM_PROCS\" | sed 's/,$//')

        if [ -n \"$CAM_PROCS\" ]; then
            echo \"cameraInUse=true\"
            echo \"cameraApps=$CAM_PROCS\"
        else
            echo \"cameraInUse=false\"
            echo \"cameraApps=\"
        fi

        # Check screen sharing
        if command -v pw-cli &>/dev/null; then
            SCREEN_STREAMS=$(pw-cli list-objects 2>/dev/null | grep -c 'media.class = \"Video/Source\"' || echo '0')
            if [ \"$SCREEN_STREAMS\" -gt 0 ]; then
                echo \"screenShareInUse=true\"
            else
                echo \"screenShareInUse=false\"
            fi
        else
            echo \"screenShareInUse=false\"
        fi
    "

    Process {
        id: privacyProcess
        command: ["sh", "-c", root.privacyQueryScript]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.parseLine(data)
        }
    }

    function parseLine(line) {
        if (!line || line.trim() === "") return

        const idx = line.indexOf("=")
        if (idx === -1) return

        const key = line.substring(0, idx).trim()
        const value = line.substring(idx + 1).trim()

        switch (key) {
            case "micInUse":
                micInUse = value === "true"
                break
            case "cameraInUse":
                cameraInUse = value === "true"
                break
            case "screenShareInUse":
                screenShareInUse = value === "true"
                break
            case "micApps":
                micApps = value.split(",").filter(s => s.trim() !== "")
                break
            case "cameraApps":
                cameraApps = value.split(" ").filter(s => s.trim() !== "")
                break
        }
    }

    // Poll regularly
    Timer {
        interval: 2000  // 2 seconds
        running: true
        repeat: true
        onTriggered: privacyProcess.running = true
    }

    // Summary for tooltip
    function summary() {
        let parts = []
        if (micInUse) {
            parts.push("Microphone: " + (micApps.length > 0 ? micApps.join(", ") : "in use"))
        }
        if (cameraInUse) {
            parts.push("Camera: " + (cameraApps.length > 0 ? cameraApps.join(", ") : "in use"))
        }
        if (screenShareInUse) {
            parts.push("Screen sharing active")
        }
        return parts.join("\n") || "No devices in use"
    }
}
