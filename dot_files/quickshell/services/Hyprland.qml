pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Hyprland workspace tracking service
Singleton {
    id: root

    // Map of monitor name -> active workspace info
    property var workspaces: ({})

    // Revision counter to force binding updates
    property int revision: 0

    // All active workspaces as a formatted string (e.g., "1 | 3")
    property string allWorkspaces: {
        void revision  // Force re-evaluation
        let ids = []
        for (const mon in workspaces) {
            if (workspaces[mon] && workspaces[mon].id) {
                ids.push(workspaces[mon].id)
            }
        }
        ids.sort((a, b) => a - b)
        return ids.length > 0 ? ids.join(" | ") : "1"
    }

    // Get workspace ID as string for a specific monitor
    // Note: Include revision in bindings to ensure updates: Services.Hyprland.revision, Services.Hyprland.getWorkspace(...)
    function getWorkspace(monitorName: string): string {
        if (workspaces[monitorName]) {
            // Prefer numeric ID over name (names can be things like "DP-1" in some configs)
            return String(workspaces[monitorName].id)
        }
        return "1"
    }

    // Get workspace ID for a specific monitor
    function getWorkspaceId(monitorName: string): int {
        if (workspaces[monitorName]) {
            return workspaces[monitorName].id || 1
        }
        return 1
    }

    // Query monitors to get active workspaces
    Process {
        id: monitorProcess
        command: ["hyprctl", "monitors", "-j"]

        property string output: ""

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                monitorProcess.output += data
            }
        }

        onExited: {
            try {
                const monitors = JSON.parse(monitorProcess.output)
                let newWorkspaces = {}

                for (const mon of monitors) {
                    if (mon.activeWorkspace) {
                        newWorkspaces[mon.name] = {
                            id: mon.activeWorkspace.id,
                            name: mon.activeWorkspace.name
                        }
                    }
                }

                root.workspaces = newWorkspaces
                root.revision++
            } catch (e) {
                console.log("Failed to parse monitor workspace data:", e)
            }
            monitorProcess.output = ""
        }
    }

    // Refresh workspace data
    function refresh() {
        monitorProcess.running = true
    }

    // Poll for workspace changes
    Timer {
        interval: 250
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
