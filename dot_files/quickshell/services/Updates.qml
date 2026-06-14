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

    // Holds the most recent process output (Process.stdout is a sink, not a
    // readable string, so we collect it here via StdioCollector below).
    property string pendingOutput: ""

    // Update query script
    readonly property string updateQueryScript: "
        if command -v rpm-ostree &>/dev/null; then
            # On ostree-container / bootc systems this reconciles against the
            # registry image (e.g. ghcr.io/binarypie-dev/hypercube:44) via the
            # privileged daemon, so it works from a user-context process.
            OUTPUT=$(rpm-ostree upgrade --check 2>/dev/null)
            if echo \"$OUTPUT\" | grep -q \"AvailableUpdate\"; then
                echo \"updateCount=1\"
                VERSION=$(echo \"$OUTPUT\" | grep -i \"Version:\" | head -1 | sed 's/.*Version:[[:space:]]*//')
                if [ -n \"$VERSION\" ]; then
                    echo \"update:New image: $VERSION\"
                else
                    echo \"update:System image update available\"
                fi
            else
                echo \"updateCount=0\"
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

        stdout: StdioCollector {
            onStreamFinished: root.pendingOutput = this.text
        }

        onExited: root.parseUpdateOutput()
        onRunningChanged: {
            if (running) {
                checking = true
                root.pendingOutput = ""
            }
        }
    }

    function parseUpdateOutput() {
        checking = false
        error = ""

        const output = root.pendingOutput || ""
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
