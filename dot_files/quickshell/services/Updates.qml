pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// System updates management
Singleton {
    id: root

    // System update status
    property bool checking: false
    property int updateCount: 0
    property var updates: []
    property string lastChecked: ""
    property string error: ""

    // Whether we need user attention
    property bool needsAttention: updateCount > 0

    // Update query script
    readonly property string updateQueryScript: "
        if command -v rpm-ostree &>/dev/null; then
            STATUS=$(rpm-ostree status --json 2>/dev/null)
            if echo \"$STATUS\" | grep -q '\"pending\"'; then
                echo \"updateCount=1\"
                echo \"update:System update available\"
            else
                UPDATES=$(rpm-ostree upgrade --check 2>/dev/null | grep -c \"Diff\" || echo \"0\")
                echo \"updateCount=$UPDATES\"
            fi

        elif command -v dnf &>/dev/null; then
            UPDATES=$(dnf check-update --quiet 2>/dev/null | grep -c \"^[a-zA-Z]\" || echo \"0\")
            echo \"updateCount=$UPDATES\"

        elif command -v apt &>/dev/null; then
            apt update -qq 2>/dev/null
            UPDATES=$(apt list --upgradable 2>/dev/null | grep -c \"upgradable\" || echo \"0\")
            echo \"updateCount=$UPDATES\"

        elif command -v pacman &>/dev/null; then
            UPDATES=$(checkupdates 2>/dev/null | wc -l || echo \"0\")
            echo \"updateCount=$UPDATES\"

        else
            echo \"updateCount=0\"
        fi

        echo \"lastChecked=$(date '+%Y-%m-%d %H:%M')\"
    "

    Process {
        id: updateProcess
        command: ["sh", "-c", root.updateQueryScript]
        running: false
        onExited: root.parseUpdateOutput()
        onRunningChanged: {
            if (running) checking = true
        }
    }

    function parseUpdateOutput() {
        checking = false
        error = ""

        const output = updateProcess.stdout || ""
        const lines = output.split("\n")
        const newUpdates = []

        for (const line of lines) {
            if (line.startsWith("update:")) {
                newUpdates.push(line.substring(7))
                continue
            }

            const idx = line.indexOf("=")
            if (idx === -1) continue

            const key = line.substring(0, idx).trim()
            const value = line.substring(idx + 1).trim()

            switch (key) {
                case "updateCount":
                    updateCount = parseInt(value) || 0
                    break
                case "lastChecked":
                    lastChecked = value
                    break
            }
        }

        updates = newUpdates
    }

    // Check for updates
    function checkUpdates() {
        if (!checking) {
            updateProcess.running = true
        }
    }

    // Auto-check timer (every 6 hours)
    Timer {
        interval: 6 * 60 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkUpdates()
    }

    // Summary string
    function summary(): string {
        if (checking) return "Checking for updates..."
        if (error) return "Error checking updates"
        if (updateCount === 0) return "System is up to date"
        if (updateCount === 1) return "1 update available"
        return updateCount + " updates available"
    }
}
