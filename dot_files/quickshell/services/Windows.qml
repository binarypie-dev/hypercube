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

    // Name of the output that currently has keyboard focus. niri only hands
    // keyboard focus to layer surfaces on its active output, so the switcher
    // overlay has to be mapped there or it never sees the Super release and
    // stays on screen forever.
    property string focusedOutput: ""

    // Screen object for focusedOutput (null until known)
    readonly property var focusedScreen: {
        for (const s of Quickshell.screens) {
            if (s.name === root.focusedOutput) return s
        }
        return null
    }

    // Latched when the switcher opens so a focus change mid-switch cannot pull
    // the overlay out from under the user.
    property string switcherOutput: ""

    // Screen the switcher overlay should live on. Falls back to the first
    // screen so exactly one instance is ever loaded.
    readonly property var switcherScreen: {
        const screens = Quickshell.screens
        if (!screens || screens.length === 0) return null
        const wanted = root.switcherActive ? root.switcherOutput : root.focusedOutput
        for (const s of screens) {
            if (s.name === wanted) return s
        }
        return screens[0]
    }

    // --- niri live state, fed by the event stream ---
    property var niriWindows: ({})     // window id -> niri window object
    property var niriWorkspaces: ({})  // workspace id -> niri workspace object
    property var focusOrder: []        // window ids (strings), most recent first

    // ---------------------------------------------------------------- niri ---

    // niri has no focus timestamp in its window IPC, so the focus history has
    // to be tracked live from the event stream. The stream also tells us which
    // output is focused, which decides where the overlay is mapped.
    Process {
        id: niriEvents
        running: true
        command: ["niri", "msg", "-j", "event-stream"]

        stdout: SplitParser {
            onRead: line => root.handleNiriEvent(line)
        }

        onExited: niriEventsRestart.restart()
    }

    Timer {
        id: niriEventsRestart
        interval: 1000
        repeat: false
        onTriggered: niriEvents.running = true
    }

    function handleNiriEvent(line) {
        if (!line) return

        let event
        try {
            event = JSON.parse(line)
        } catch (e) {
            return
        }

        if (event.WindowsChanged) {
            const map = {}
            for (const w of event.WindowsChanged.windows) {
                map[String(w.id)] = w
            }
            root.niriWindows = map
            for (const w of event.WindowsChanged.windows) {
                if (w.is_focused) root.noteFocus(w.id)
            }
            root.pruneFocusOrder()
            root.updateFocusedOutput()
        } else if (event.WindowOpenedOrChanged) {
            const w = event.WindowOpenedOrChanged.window
            const map = Object.assign({}, root.niriWindows)
            map[String(w.id)] = w
            root.niriWindows = map
            if (w.is_focused) root.noteFocus(w.id)
            root.updateFocusedOutput()
        } else if (event.WindowClosed) {
            const id = String(event.WindowClosed.id)
            const map = Object.assign({}, root.niriWindows)
            delete map[id]
            root.niriWindows = map
            root.focusOrder = root.focusOrder.filter(i => i !== id)
        } else if (event.WindowFocusChanged) {
            root.noteFocus(event.WindowFocusChanged.id)
            root.updateFocusedOutput()
        } else if (event.WorkspacesChanged) {
            const map = {}
            for (const ws of event.WorkspacesChanged.workspaces) {
                map[String(ws.id)] = ws
            }
            root.niriWorkspaces = map
            root.updateFocusedOutput()
        } else if (event.WorkspaceActivated) {
            root.applyWorkspaceActivated(event.WorkspaceActivated)
            root.updateFocusedOutput()
        }
    }

    // Move a window to the front of the focus history.
    function noteFocus(id) {
        if (id === null || id === undefined) return
        const key = String(id)
        if (root.focusOrder[0] === key) return
        const next = root.focusOrder.filter(i => i !== key)
        next.unshift(key)
        root.focusOrder = next
    }

    function pruneFocusOrder() {
        root.focusOrder = root.focusOrder.filter(id => root.niriWindows[id] !== undefined)
    }

    // niri sends WorkspaceActivated rather than a full workspace list when
    // focus moves, so patch the cached flags instead of re-querying.
    function applyWorkspaceActivated(ev) {
        const target = root.niriWorkspaces[String(ev.id)]
        if (!target) return

        const map = {}
        for (const key in root.niriWorkspaces) {
            const ws = Object.assign({}, root.niriWorkspaces[key])
            const isTarget = String(ws.id) === String(ev.id)
            if (ws.output === target.output) ws.is_active = isTarget
            if (ev.focused) ws.is_focused = isTarget
            map[key] = ws
        }
        root.niriWorkspaces = map
    }

    // Prefer the focused workspace's output; fall back to the workspace of the
    // most recently focused window (focus can land on an empty workspace, and
    // not every niri release reports is_focused on workspaces).
    function updateFocusedOutput() {
        for (const key in root.niriWorkspaces) {
            const ws = root.niriWorkspaces[key]
            if (ws.is_focused && ws.output) {
                root.focusedOutput = ws.output
                return
            }
        }

        const focused = root.niriWindows[root.focusOrder[0]]
        if (focused) {
            const ws = root.niriWorkspaces[String(focused.workspace_id)]
            if (ws && ws.output) root.focusedOutput = ws.output
        }
    }

    // Build the switcher list from live niri state, most recently focused first.
    function windowsFromNiri() {
        const list = []
        for (const id in root.niriWindows) {
            list.push(root.niriWindows[id])
        }

        const rank = w => {
            const i = root.focusOrder.indexOf(String(w.id))
            return i === -1 ? Number.MAX_SAFE_INTEGER : i
        }
        list.sort((a, b) => rank(a) - rank(b))

        return list.map(w => {
            const ws = root.niriWorkspaces[String(w.workspace_id)]
            return {
                address: String(w.id),
                class: w.app_id || "",
                title: w.title || "",
                workspace: ws ? { id: ws.idx, name: ws.name || String(ws.idx) } : null
            }
        })
    }

    // ------------------------------------------------------------ switcher ---

    Process {
        id: focusProcess
    }

    function prefetchIcons() {
        for (const w of root.windows) {
            if (w.class) IconResolver.getIcon(w.class)
        }
    }

    function refresh() {
        root.windows = root.windowsFromNiri()
        root.prefetchIcons()
    }

    // step is where the selection starts relative to the focused window: 1 for
    // Tab, -1 for Shift+Tab.
    function startSwitcher(step) {
        refresh()
        activateSwitcher(step === undefined ? 1 : step)
    }

    function activateSwitcher(step) {
        if (root.windows.length === 0) {
            root.switcherActive = false
            return
        }

        const n = root.windows.length
        root.currentIndex = ((step % n) + n) % n
        root.switcherOutput = root.focusedOutput
        root.switcherActive = true
    }

    function nextWindow() {
        if (root.switcherActive) {
            if (root.windows.length === 0) return
            root.currentIndex = (root.currentIndex + 1) % root.windows.length
        } else {
            startSwitcher(1)
        }
    }

    function prevWindow() {
        if (root.switcherActive) {
            if (root.windows.length === 0) return
            root.currentIndex = (root.currentIndex - 1 + root.windows.length) % root.windows.length
        } else {
            startSwitcher(-1)
        }
    }

    function selectWindow() {
        if (!root.switcherActive) return

        if (root.windows.length === 0 || root.currentIndex >= root.windows.length) {
            cancelSwitcher()
            return
        }

        const window = root.windows[root.currentIndex]
        focusProcess.command = ["niri", "msg", "action", "focus-window", "--id", window.address]
        focusProcess.running = true

        root.switcherActive = false
        root.currentIndex = 0
    }

    function cancelSwitcher() {
        root.switcherActive = false
        root.currentIndex = 0
    }
}
