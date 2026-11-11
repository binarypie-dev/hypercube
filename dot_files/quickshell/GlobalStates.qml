pragma Singleton

import QtQuick
import Quickshell

// Centralized state management singleton
// All global UI states are managed here to prevent scattered state definitions
Singleton {
    id: root

    // Active screen for overlays (sidebars, launcher, etc.)
    property var activeScreen: null

    // Screen position tracking for multi-monitor layouts
    // The leftmost screen shows the app launcher, rightmost shows notifications/clock
    property var leftmostScreen: null
    property var rightmostScreen: null

    // Determine leftmost and rightmost screens from their positions in the
    // compositor's global layout (works the same on Hyprland and niri)
    function updateScreenPositions() {
        let screens = Quickshell.screens
        if (!screens || screens.length === 0) return

        let left = screens[0]
        let right = screens[0]
        for (let i = 1; i < screens.length; i++) {
            const s = screens[i]
            if (s.x < left.x) left = s
            if (s.x > right.x) right = s
        }

        leftmostScreen = left
        rightmostScreen = right
    }

    // Check if a screen is the leftmost
    function isLeftmostScreen(screen): bool {
        if (!screen) return false
        // Single monitor case
        if (Quickshell.screens.length === 1) return true
        return screen === leftmostScreen
    }

    // Check if a screen is the rightmost
    function isRightmostScreen(screen): bool {
        if (!screen) return false
        // Single monitor case
        if (Quickshell.screens.length === 1) return true
        return screen === rightmostScreen
    }

    // Update screen positions on startup and when screens change
    Component.onCompleted: {
        // Delay to ensure screens are available
        Qt.callLater(updateScreenPositions)
    }

    // Watch for screen changes
    Connections {
        target: Quickshell
        function onScreensChanged() {
            root.updateScreenPositions()
        }
    }

    // Also update when screens list changes length
    property int screenCount: Quickshell.screens.length
    onScreenCountChanged: {
        updateScreenPositions()
    }

    // Centered hub (launcher, quick settings, window switcher), opened with
    // Mod+Space (apps), Mod+N (notifications) or Mod+Tab (windows).
    // Tabs in display order (left to right; Tab / Ctrl+1-9 follow it); `mode` is the label shown in the status bar and
    // `insert` picks the insert-mode (green) accent over visual (purple).
    readonly property var hubTabs: [
        // `group` places the icon in the hub title bar:
        //   left  -> after the left edge, before the tab name
        //   clock -> just left of the date/time
        //   end   -> right of the date/time
        { id: "windows",       label: "windows", mode: "WINDOWS",   insert: false, group: "left" },
        { id: "apps",          label: "apps",    mode: "APPS",      insert: true,  group: "left" },
        { id: "notifications", label: "notify",  mode: "NOTIFY",    insert: false, group: "left" },
        { id: "audio",         label: "audio",   mode: "AUDIO",     insert: false, group: "left" },
        { id: "network",       label: "net",     mode: "NETWORK",   insert: false, group: "left" },
        { id: "bluetooth",     label: "bt",      mode: "BLUETOOTH", insert: false, group: "left" },
        { id: "weather",       label: "weather", mode: "WEATHER",   insert: false, group: "clock" },
        { id: "calendar",      label: "cal",     mode: "CALENDAR",  insert: false, group: "clock" },
        { id: "thermals",      label: "temps",   mode: "THERMALS",  insert: false, group: "end" },
        { id: "system",        label: "system",  mode: "SYSTEM",    insert: false, group: "end" }
    ]

    property bool hubOpen: false
    property string hubTab: "apps"
    // Screen the hub is shown on. On niri this must be the focused output:
    // niri only gives keyboard focus to layer surfaces on its active output.
    property var hubScreen: null

    readonly property var currentHubTab: {
        for (const t of hubTabs) if (t.id === hubTab) return t
        return hubTabs[0]
    }

    // OSD (On-Screen Display) state
    property bool osdVisible: false
    property string osdType: "volume" // "volume", "brightness", "mic", "tooltip"
    property real osdValue: 0.0
    property bool osdMuted: false
    property string osdTooltipText: ""  // For tooltip mode

    // Notification states
    property int unreadNotificationCount: 0
    property bool doNotDisturb: false

    // Bar states
    property bool barExpanded: false

    // Settings panel
    property bool settingsOpen: false

    // Welcome wizard (first-run)
    property bool welcomeActive: false

    // Screen zoom (accessibility)
    property real screenZoom: 1.0
    Behavior on screenZoom {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    // Super key tracking
    property bool superDown: false
    property bool superReleaseMightTrigger: false

    // OSD auto-hide timer
    Timer {
        id: osdHideTimer
        interval: 1500
        repeat: false
        onTriggered: osdVisible = false
    }

    onOsdVisibleChanged: {
        if (osdVisible) {
            osdHideTimer.restart()
        }
    }

    // Open the hub on `screen` at `tab`
    function openHub(screen, tab) {
        if (screen) {
            activeScreen = screen
            hubScreen = screen
        }
        hubTab = tab || "apps"
        hubOpen = true
    }

    // Toggle: same tab on the same screen closes; anything else opens/switches
    function toggleHub(screen, tab) {
        const targetTab = tab || "apps"
        if (hubOpen && hubTab === targetTab && (!screen || hubScreen === screen)) {
            closeAll()
        } else {
            openHub(screen, targetTab)
        }
    }

    // Move `step` tabs left (-1) or right (+1), wrapping
    function cycleHubTab(step) {
        let i = hubTabs.findIndex(t => t.id === hubTab)
        const n = hubTabs.length
        hubTab = hubTabs[(((i + step) % n) + n) % n].id
    }

    function closeAll() {
        hubOpen = false
        hubTab = "apps"
        settingsOpen = false
    }
}
