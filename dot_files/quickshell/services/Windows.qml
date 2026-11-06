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

    // Query windows from the compositor. On niri, windows and workspaces are
    // fetched together so each window can be labelled with its workspace number.
    readonly property string windowQueryScript: Compositor.isNiri
        ? "printf '{\"windows\":%s,\"workspaces\":%s}' \"$(niri msg -j windows)\" \"$(niri msg -j workspaces)\""
        : "hyprctl clients -j"

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
                const data = JSON.parse(windowProcess.output)
                const visible = Compositor.isNiri ? root.fromNiri(data) : root.fromHyprland(data)
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

    // Hyprland: filter out hidden windows and sort by focusHistoryID
    // (0 = currently focused, then most recently focused)
    function fromHyprland(clients) {
        const visible = clients.filter(w => w.mapped && !w.hidden)
        visible.sort((a, b) => a.focusHistoryID - b.focusHistoryID)
        return visible
    }

    // niri: map windows to the fields the switcher uses (class, title,
    // address, workspace.id) and sort most recently focused first.
    function fromNiri(data) {
        const wsById = {}
        for (const ws of data.workspaces) {
            wsById[ws.id] = ws
        }

        const focusTime = w => {
            if (w.is_focused) return Number.MAX_VALUE
            const t = w.focus_timestamp
            return t ? t.secs * 1e9 + t.nanos : 0
        }

        const sorted = data.windows.slice().sort((a, b) => focusTime(b) - focusTime(a))
        return sorted.map(w => {
            const ws = w.workspace_id !== null && w.workspace_id !== undefined ? wsById[w.workspace_id] : null
            return {
                address: String(w.id),
                class: w.app_id || "",
                title: w.title || "",
                workspace: ws ? { id: ws.idx, name: ws.name || String(ws.idx) } : null
            }
        })
    }

    Process {
        id: focusProcess
        command: ["hyprctl", "dispatch", "hl.dsp.focus({ window = \"address:0x0\" })"]
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
        focusProcess.command = Compositor.isNiri
            ? ["niri", "msg", "action", "focus-window", "--id", window.address]
            : ["hyprctl", "dispatch", "hl.dsp.focus({ window = \"address:" + window.address + "\" })"]
        focusProcess.running = true
        switcherActive = false
    }

    function cancelSwitcher() {
        switcherActive = false
        currentIndex = 0
    }
}
