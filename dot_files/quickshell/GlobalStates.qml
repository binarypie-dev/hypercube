pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

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

    // Determine leftmost and rightmost screens using Hyprland monitor data
    function updateScreenPositions() {
        let screens = Quickshell.screens
        if (!screens || screens.length === 0) return

        // For single monitor, it's both left and right
        if (screens.length === 1) {
            leftmostScreen = screens[0]
            rightmostScreen = screens[0]
            return
        }

        // Query Hyprland for monitor positions
        monitorQuery.running = true
    }

    // Process to get Hyprland monitor info
    Process {
        id: monitorQuery
        command: ["hyprctl", "monitors", "-j"]

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                if (!data || data.trim() === "") return

                try {
                    const monitors = JSON.parse(data)
                    let minX = 999999
                    let maxX = -999999
                    let leftName = ""
                    let rightName = ""

                    for (const mon of monitors) {
                        if (mon.x < minX) {
                            minX = mon.x
                            leftName = mon.name
                        }
                        if (mon.x > maxX) {
                            maxX = mon.x
                            rightName = mon.name
                        }
                    }

                    // Find matching Quickshell screens by name
                    for (let i = 0; i < Quickshell.screens.length; i++) {
                        const s = Quickshell.screens[i]
                        if (s.name === leftName) {
                            root.leftmostScreen = s
                        }
                        if (s.name === rightName) {
                            root.rightmostScreen = s
                        }
                    }
                } catch (e) {
                    console.log("Failed to parse monitor data:", e)
                }
            }
        }
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

    // Sidebar visibility
    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false

    // Right sidebar view mode: "default", "bluetooth", "audio", "calendar", "notifications"
    property string sidebarRightView: "default"

    // OSD (On-Screen Display) state
    property bool osdVisible: false
    property string osdType: "volume" // "volume", "brightness", "mic"
    property real osdValue: 0.0
    property bool osdMuted: false

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

    // Super key tracking (for workspace numbers, etc.)
    property bool superDown: false
    property bool superReleaseMightTrigger: false

    // Close other panels when left sidebar opens
    onSidebarLeftOpenChanged: {
        if (sidebarLeftOpen) {
            sidebarRightOpen = false
        }
    }

    // Mutual exclusion for right sidebar
    onSidebarRightOpenChanged: {
        if (sidebarRightOpen) {
            sidebarLeftOpen = false
        }
    }

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

    // Function to toggle panels (accepts screen to show on)
    function toggleSidebarLeft(screen) {
        if (sidebarLeftOpen && activeScreen === screen) {
            sidebarLeftOpen = false
        } else {
            activeScreen = screen
            sidebarLeftOpen = true
        }
    }

    function toggleSidebarRight(screen, view) {
        const targetView = view || "default"
        if (sidebarRightOpen && activeScreen === screen && sidebarRightView === targetView) {
            sidebarRightOpen = false
            sidebarRightView = "default"
        } else {
            activeScreen = screen
            sidebarRightView = targetView
            sidebarRightOpen = true
        }
    }

    function closeAll() {
        sidebarLeftOpen = false
        sidebarRightOpen = false
        sidebarRightView = "default"
        settingsOpen = false
    }
}
