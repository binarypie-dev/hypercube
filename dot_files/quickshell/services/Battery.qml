pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool present: false
    property int percent: 100
    property bool charging: false
    property bool pluggedIn: false
    property string status: "Unknown"
    property int timeToEmpty: 0  // minutes
    property int timeToFull: 0   // minutes

    // Battery health
    property int designCapacity: 0
    property int fullCapacity: 0
    property real health: 1.0

    // Low battery threshold
    readonly property int lowThreshold: 20
    readonly property int criticalThreshold: 10

    property bool isLow: percent <= lowThreshold && !charging
    property bool isCritical: percent <= criticalThreshold && !charging

    // Battery query script
    readonly property string batteryQueryScript: "
        BAT_PATH=\"\"
        for bat in /sys/class/power_supply/BAT*; do
            if [ -d \"$bat\" ]; then
                BAT_PATH=\"$bat\"
                break
            fi
        done

        if [ -z \"$BAT_PATH\" ]; then
            echo \"present=false\"
            exit 0
        fi

        echo \"present=true\"

        if [ -f \"$BAT_PATH/capacity\" ]; then
            echo \"percent=$(cat $BAT_PATH/capacity)\"
        fi

        if [ -f \"$BAT_PATH/status\" ]; then
            STATUS=$(cat $BAT_PATH/status)
            echo \"status=$STATUS\"
            case \"$STATUS\" in
                Charging) echo \"charging=true\" ;;
                *) echo \"charging=false\" ;;
            esac
        fi

        for ac in /sys/class/power_supply/AC* /sys/class/power_supply/ADP*; do
            if [ -f \"$ac/online\" ]; then
                if [ \"$(cat $ac/online)\" = \"1\" ]; then
                    echo \"pluggedIn=true\"
                else
                    echo \"pluggedIn=false\"
                fi
                break
            fi
        done

        if [ -f \"$BAT_PATH/energy_now\" ] && [ -f \"$BAT_PATH/power_now\" ]; then
            ENERGY=$(cat $BAT_PATH/energy_now)
            POWER=$(cat $BAT_PATH/power_now)
            if [ \"$POWER\" -gt 0 ]; then
                HOURS=$(echo \"scale=2; $ENERGY / $POWER\" | bc 2>/dev/null || echo \"0\")
                MINUTES=$(echo \"scale=0; $HOURS * 60\" | bc 2>/dev/null || echo \"0\")
                echo \"timeRemaining=$MINUTES\"
            fi
        fi

        if [ -f \"$BAT_PATH/energy_full_design\" ] && [ -f \"$BAT_PATH/energy_full\" ]; then
            DESIGN=$(cat $BAT_PATH/energy_full_design)
            FULL=$(cat $BAT_PATH/energy_full)
            echo \"designCapacity=$DESIGN\"
            echo \"fullCapacity=$FULL\"
        fi
    "

    // UPower D-Bus would be ideal, but we'll use /sys/class/power_supply
    Process {
        id: batteryProcess
        command: ["sh", "-c", root.batteryQueryScript]
        running: true
        onExited: root.parseOutput()
    }

    function parseOutput() {
        const output = batteryProcess.stdout
        if (!output) return
        const lines = output.split("\n")

        for (const line of lines) {
            const [key, value] = line.split("=")
            if (!key || !value) continue

            switch (key.trim()) {
                case "present":
                    present = value.trim() === "true"
                    break
                case "percent":
                    percent = parseInt(value.trim()) || 100
                    break
                case "charging":
                    charging = value.trim() === "true"
                    break
                case "pluggedIn":
                    pluggedIn = value.trim() === "true"
                    break
                case "status":
                    status = value.trim()
                    break
                case "timeRemaining":
                    const mins = parseInt(value.trim()) || 0
                    if (charging) {
                        timeToFull = mins
                    } else {
                        timeToEmpty = mins
                    }
                    break
                case "designCapacity":
                    designCapacity = parseInt(value.trim()) || 0
                    break
                case "fullCapacity":
                    fullCapacity = parseInt(value.trim()) || 0
                    if (designCapacity > 0) {
                        health = fullCapacity / designCapacity
                    }
                    break
            }
        }
    }

    // Update timer
    Timer {
        interval: 30000  // 30 seconds
        running: true
        repeat: true
        onTriggered: batteryProcess.running = true
    }

    // Time remaining as string
    function timeRemainingString(): string {
        const mins = charging ? timeToFull : timeToEmpty
        if (mins <= 0) return ""

        const hours = Math.floor(mins / 60)
        const minutes = mins % 60

        if (hours > 0) {
            return hours + "h " + minutes + "m"
        }
        return minutes + "m"
    }
}
