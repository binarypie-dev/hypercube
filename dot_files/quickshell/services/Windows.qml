pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Window/client tracking service for app switcher
Singleton {
    id: root

    property var windows: []  // List of windows sorted by focus history
    property int currentIndex: 0
    property bool switcherActive: false

    // Query windows from Hyprland
    readonly property string windowQueryScript: "hyprctl clients -j"

    Process {
        id: windowProcess
        command: ["sh", "-c", root.windowQueryScript]

        property string output: ""

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                windowProcess.output += data
            }
        }

        onExited: {
            try {
                const clients = JSON.parse(windowProcess.output)
                // Filter out hidden windows and sort by focusHistoryID
                const visible = clients.filter(w => w.mapped && !w.hidden)
                visible.sort((a, b) => a.focusHistoryID - b.focusHistoryID)
                root.windows = visible

                // Pre-fetch icons for all window classes via IconResolver
                for (const w of visible) {
                    if (w.class) {
                        IconResolver.getIcon(w.class)
                    }
                }
            } catch (e) {
                console.log("Failed to parse windows:", e)
                root.windows = []
            }
            windowProcess.output = ""
        }
    }

    Process {
        id: focusProcess
        command: ["hyprctl", "dispatch", "focuswindow", "address:0x0"]
    }

    function refresh() {
        windowProcess.running = true
    }

    function startSwitcher() {
        refresh()
        switcherActive = true
        currentIndex = 0
    }

    function nextWindow() {
        if (windows.length === 0) return
        currentIndex = (currentIndex + 1) % windows.length
    }

    function prevWindow() {
        if (windows.length === 0) return
        currentIndex = (currentIndex - 1 + windows.length) % windows.length
    }

    function selectWindow() {
        if (windows.length === 0 || currentIndex >= windows.length) {
            switcherActive = false
            return
        }

        const window = windows[currentIndex]
        focusProcess.command = ["hyprctl", "dispatch", "focuswindow", "address:" + window.address]
        focusProcess.running = true
        switcherActive = false
    }

    function cancelSwitcher() {
        switcherActive = false
        currentIndex = 0
    }
}
