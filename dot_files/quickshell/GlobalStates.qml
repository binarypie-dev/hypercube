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

    // Sidebar visibility
    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false

    // Left sidebar view mode: "apps", "updates"
    property string sidebarLeftView: "apps"

    // Right sidebar view mode: "default", "bluetooth", "audio", "calendar", "notifications"
    property string sidebarRightView: "default"

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
    function toggleSidebarLeft(screen, view) {
        const targetView = view || "apps"
        if (sidebarLeftOpen && activeScreen === screen && sidebarLeftView === targetView) {
            sidebarLeftOpen = false
            sidebarLeftView = "apps"
        } else {
            activeScreen = screen
            sidebarLeftView = targetView
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
        sidebarLeftView = "apps"
        sidebarRightView = "default"
        settingsOpen = false
    }
}
