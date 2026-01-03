pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../modules/common" as Common

// System updates and flatpak preinstall management
Singleton {
    id: root

    // System update status
    property bool checking: false
    property int updateCount: 0
    property var updates: []
    property string lastChecked: ""
    property string error: ""

    // Flatpak preinstall status
    property bool preinstallCompleted: Common.Config.preinstallCompleted
    property bool preinstallRunning: false
    property string preinstallStatus: ""
    property var preinstallLog: []
    property int preinstallTotal: 0
    property int preinstallCurrent: 0

    // Whether we need user attention
    property bool needsAttention: !preinstallCompleted || updateCount > 0

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

    // Count preinstall files script
    readonly property string countPreinstallScript: `
        PREINSTALL_DIR="/usr/share/flatpak/preinstall.d"
        if [[ -d "$PREINSTALL_DIR" ]]; then
            count=$(ls -1 "$PREINSTALL_DIR"/*.preinstall 2>/dev/null | wc -l)
            echo "total=$count"
        else
            echo "total=0"
        fi
    `

    Process {
        id: updateProcess
        command: ["sh", "-c", root.updateQueryScript]
        running: false
        onExited: root.parseUpdateOutput()
        onRunningChanged: {
            if (running) checking = true
        }
    }

    Process {
        id: countProcess
        command: ["sh", "-c", root.countPreinstallScript]
        running: false
        onExited: {
            const output = stdout || ""
            const match = output.match(/total=(\d+)/)
            if (match) {
                root.preinstallTotal = parseInt(match[1]) || 0
            }
        }
    }

    Process {
        id: preinstallProcess
        command: ["/usr/libexec/flatpak-preinstall"]
        running: false

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data.trim() === "") return
                root.preinstallLog = [...root.preinstallLog, data]
                root.preinstallStatus = data

                // Track progress
                if (data.startsWith("Installing:") || data.startsWith("Already installed:")) {
                    root.preinstallCurrent++
                }
            }
        }

        onRunningChanged: {
            if (running) {
                root.preinstallRunning = true
                root.preinstallLog = []
                root.preinstallStatus = "Starting flatpak preinstall..."
                root.preinstallCurrent = 0
            }
        }

        onExited: {
            root.preinstallRunning = false
            if (exitCode === 0) {
                root.preinstallStatus = "Preinstall complete"
                root.preinstallCompleted = true
                Common.Config.preinstallCompleted = true
                Common.Config.save()
            } else {
                root.preinstallStatus = "Preinstall failed (exit code: " + exitCode + ")"
            }
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

    // Run flatpak preinstall
    function runPreinstall() {
        if (!preinstallRunning) {
            preinstallProcess.running = true
        }
    }

    // Reset preinstall status (to allow re-running)
    function resetPreinstall() {
        preinstallCompleted = false
        Common.Config.preinstallCompleted = false
        Common.Config.save()
    }

    // Count preinstall files
    function countPreinstallApps() {
        countProcess.running = true
    }

    // Auto-check timer (every 6 hours)
    Timer {
        interval: 6 * 60 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkUpdates()
    }

    // On startup, count preinstall apps and check if we should auto-run
    Component.onCompleted: {
        countPreinstallApps()
        // Try to auto-run preinstall if network is already connected
        autoPreinstallTimer.start()
    }

    // Auto-run preinstall when network becomes available
    Connections {
        target: Network

        function onConnectedChanged() {
            if (Network.connected && !root.preinstallCompleted && !root.preinstallRunning) {
                // Small delay to let network settle
                autoPreinstallTimer.start()
            }
        }
    }

    // Timer to auto-run preinstall (gives network time to settle)
    Timer {
        id: autoPreinstallTimer
        interval: 3000  // 3 seconds
        onTriggered: {
            if (Network.connected && !root.preinstallCompleted && !root.preinstallRunning) {
                console.log("Updates: Auto-starting preinstall...")
                runPreinstall()
            }
        }
    }

    // Summary string
    function summary(): string {
        if (checking) return "Checking for updates..."
        if (error) return "Error checking updates"
        if (updateCount === 0) return "System is up to date"
        if (updateCount === 1) return "1 update available"
        return updateCount + " updates available"
    }

    // Preinstall progress (0-100)
    function preinstallProgress(): real {
        if (preinstallTotal === 0) return 0
        return (preinstallCurrent / preinstallTotal) * 100
    }
}
