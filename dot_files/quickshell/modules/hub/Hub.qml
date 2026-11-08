import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../common" as Common
import "../../" as Root
import "../../services" as Services

// Centered hub: app launcher, quick settings and window switcher as tabs in one floating
// TUI-style window. Replaces the old left/right sidebars so it can always
// open on the focused output (niri only focuses layer surfaces there).
//
// Keys (window-level shortcuts, so they work even while the search box has
// focus):  Tab / Shift+Tab or Ctrl+L / Ctrl+H  next / previous tab
//          Ctrl+1 .. Ctrl+9                    jump to tab
//          Esc                                 clear search (apps), else close
PanelWindow {
    id: root

    required property var targetScreen
    screen: targetScreen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Float over everything; never reserve space or re-tile windows
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    visible: Root.GlobalStates.hubOpen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "hub"

    readonly property var tabs: Root.GlobalStates.hubTabs
    readonly property string currentTab: Root.GlobalStates.hubTab
    readonly property color modeColor: Root.GlobalStates.currentHubTab.insert
        ? Common.Appearance.colors.modeInsert
        : Common.Appearance.colors.modeVisual

    // Give the right thing keyboard focus: the search box on apps, otherwise
    // the content scope (so the window still has an active focus item)
    function focusContent() {
        const item = tabLoader.item
        if (item && typeof item.focusSearch === "function") {
            item.focusSearch()
        } else {
            contentScope.forceActiveFocus()
        }
    }

    // Tab icons mirror the live state the old status bar showed
    function tabIcon(id: string): string {
        const I = Common.Icons
        switch (id) {
            case "apps": return I.icons.apps
            case "notifications":
                if (Root.GlobalStates.doNotDisturb) return I.icons.doNotDisturb
                return Root.GlobalStates.unreadNotificationCount > 0 ? I.icons.notificationActive : I.icons.notification
            case "audio":
                return Services.Audio.muted ? I.icons.volumeOff : I.volumeIcon(Services.Audio.volume * 100, false)
            case "network":
                if (!Services.Network.connected)
                    return Services.Network.wifiAvailable ? I.icons.wifiOff : I.icons.ethernetOff
                return Services.Network.type === "wifi" ? I.wifiIcon(Services.Network.strength, true) : I.icons.ethernet
            case "bluetooth":
                if (!Services.BluetoothStatus.powered) return I.icons.bluetoothOff
                return Services.BluetoothStatus.connected ? I.icons.bluetoothConnected : I.icons.bluetooth
            case "calendar": return I.icons.calendar
            case "weather":
                return Services.Weather.ready
                    ? I.weatherIcon(Services.Weather.condition, Services.Weather.isNight)
                    : I.icons.cloudy
            case "system":
                if (!Services.Battery.present) return I.icons.power
                if (Services.Battery.pluggedIn && Services.Battery.percent >= 95) return I.icons.plug
                if (Services.Battery.charging) return I.icons.batteryCharging
                return I.batteryIcon(Services.Battery.percent, false)
            case "windows": return I.icons.list
        }
        return I.icons.apps
    }

    // Resting (unselected) color per tab
    function tabIconColor(id: string): color {
        const C = Common.Appearance.colors
        switch (id) {
            case "audio": return Services.Audio.muted ? C.comment : C.fgDark
            case "network": return Services.Network.connected ? C.fgDark : C.comment
            case "bluetooth":
                if (Services.BluetoothStatus.connected) return C.blue
                return Services.BluetoothStatus.powered ? C.fgDark : C.comment
            case "weather": return C.cyan
            case "system":
                if (Services.Battery.present && Services.Battery.percent <= 20 && !Services.Battery.charging) return C.error
                return C.fgDark
        }
        return C.fgDark
    }

    // Tabs that want attention get an orange icon + dot
    function tabAlert(id: string): bool {
        if (id === "notifications")
            return Root.GlobalStates.unreadNotificationCount > 0 && !Root.GlobalStates.doNotDisturb
        if (id === "system") return Services.Updates.needsAttention
        return false
    }

    function jumpTo(index) {
        if (index >= 0 && index < tabs.length) Root.GlobalStates.hubTab = tabs[index].id
    }

    function handleEscape() {
        const item = tabLoader.item
        // Views may consume Escape first (e.g. clearing the search query)
        if (item && typeof item.handleEscape === "function" && item.handleEscape()) return
        Root.GlobalStates.closeAll()
    }

    onVisibleChanged: if (visible) Qt.callLater(focusContent)
    onCurrentTabChanged: Qt.callLater(focusContent)

    // --- Keyboard shortcuts -------------------------------------------------
    // Shortcuts must live under an Item so they resolve the QQuickWindow
    // (PanelWindow itself isn't an Item). Window-level shortcuts fire before
    // the focused search box sees the key.
    Item {
        Shortcut { sequences: ["Tab", "Ctrl+L"]; onActivated: Root.GlobalStates.cycleHubTab(1) }
        Shortcut { sequences: ["Backtab", "Shift+Tab", "Ctrl+H"]; onActivated: Root.GlobalStates.cycleHubTab(-1) }
        Shortcut { sequence: "Escape"; onActivated: root.handleEscape() }
        Shortcut { sequence: "Ctrl+1"; onActivated: root.jumpTo(0) }
        Shortcut { sequence: "Ctrl+2"; onActivated: root.jumpTo(1) }
        Shortcut { sequence: "Ctrl+3"; onActivated: root.jumpTo(2) }
        Shortcut { sequence: "Ctrl+4"; onActivated: root.jumpTo(3) }
        Shortcut { sequence: "Ctrl+5"; onActivated: root.jumpTo(4) }
        Shortcut { sequence: "Ctrl+6"; onActivated: root.jumpTo(5) }
        Shortcut { sequence: "Ctrl+7"; onActivated: root.jumpTo(6) }
        Shortcut { sequence: "Ctrl+8"; onActivated: root.jumpTo(7) }
        Shortcut { sequence: "Ctrl+9"; onActivated: root.jumpTo(8) }
    }

    // One icon tab in the title bar
    Component {
        id: tabDelegate

        Item {
            id: tabItem
            required property var modelData
            readonly property bool selected: modelData.id === root.currentTab
            readonly property bool alert: root.tabAlert(modelData.id)

            Layout.fillHeight: true
            Layout.preferredWidth: 34

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 3
                anchors.bottomMargin: 2
                radius: Common.Appearance.rounding.tiny
                color: tabItem.selected
                    ? Common.Appearance.colors.bgVisual
                    : (tabMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
            }

            Common.Icon {
                anchors.centerIn: parent
                name: root.tabIcon(tabItem.modelData.id)
                size: Common.Appearance.sizes.iconSmall
                color: tabItem.alert
                    ? Common.Appearance.colors.orange
                    : (tabItem.selected
                        ? Common.Appearance.colors.fg
                        : root.tabIconColor(tabItem.modelData.id))
            }

            // Attention dot (unread notifications, pending update)
            Rectangle {
                visible: tabItem.alert
                width: 6
                height: 6
                radius: 3
                color: Common.Appearance.colors.orange
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 6
                anchors.rightMargin: 6
            }

            // Selected-tab marker in the mode color
            Rectangle {
                visible: tabItem.selected
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 10
                height: 2
                color: root.modeColor
            }

            MouseArea {
                id: tabMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Root.GlobalStates.hubTab = tabItem.modelData.id
            }
        }
    }

    // Click anywhere outside the panel to close
    MouseArea {
        anchors.fill: parent
        onClicked: Root.GlobalStates.closeAll()
    }

    // --- Panel ---------------------------------------------------------------
    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.9, 760)
        height: Math.min(parent.height * 0.8, 620)
        radius: Common.Appearance.rounding.tiny
        color: Qt.rgba(
            Common.Appearance.colors.bgDark.r,
            Common.Appearance.colors.bgDark.g,
            Common.Appearance.colors.bgDark.b,
            0.96
        )
        border.width: Common.Appearance.borderWidth.thin
        border.color: Common.Appearance.colors.border

        // Swallow clicks on the panel background so they don't close the hub
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Common.Appearance.borderWidth.thin
            spacing: 0

            // Title bar: tabs on the left; weather, calendar, clock, power on the right
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                color: Common.Appearance.colors.bgHighlight

                // Mode-colored underline across the title bar
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: root.modeColor

                    Behavior on color {
                        ColorAnimation { duration: Common.Appearance.animation.fast }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Common.Appearance.spacing.small
                    anchors.rightMargin: Common.Appearance.spacing.small
                    spacing: 0

                    // Left icon tabs
                    Repeater {
                        model: root.tabs.filter(t => t.group === "left")
                        delegate: tabDelegate
                    }

                    // Current tab name
                    Text {
                        Layout.leftMargin: Common.Appearance.spacing.medium
                        text: Root.GlobalStates.currentHubTab.mode
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.small
                        font.bold: true
                        color: root.modeColor
                    }

                    Item { Layout.fillWidth: true }

                    // Weather + calendar, just left of the clock
                    Repeater {
                        model: root.tabs.filter(t => t.group === "clock")
                        delegate: tabDelegate
                    }

                    // Clock
                    Text {
                        Layout.leftMargin: Common.Appearance.spacing.small
                        Layout.rightMargin: Common.Appearance.spacing.small
                        text: Services.DateTime.shortDateString + "  " + Services.DateTime.timeString
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.colors.fgDark
                    }

                    // Power / system, far right
                    Repeater {
                        model: root.tabs.filter(t => t.group === "end")
                        delegate: tabDelegate
                    }
                }
            }

            // Tab content
            FocusScope {
                id: contentScope
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: Common.Appearance.spacing.medium
                Layout.rightMargin: Common.Appearance.spacing.medium
                Layout.topMargin: Common.Appearance.spacing.medium
                Layout.bottomMargin: Common.Appearance.spacing.medium
                clip: true

                Loader {
                    id: tabLoader
                    anchors.fill: parent
                    focus: true
                    active: root.visible
                    source: {
                        switch (root.currentTab) {
                            case "apps": return "../panels/ApplicationView.qml"
                            case "notifications": return "../panels/NotificationsView.qml"
                            case "audio": return "../panels/AudioView.qml"
                            case "network": return "../panels/NetworkView.qml"
                            case "bluetooth": return "../panels/BluetoothView.qml"
                            case "calendar": return "../panels/CalendarView.qml"
                            case "weather": return "../panels/WeatherView.qml"
                            case "system": return "../panels/SystemView.qml"
                            case "windows": return "../panels/WindowsView.qml"
                        }
                        return ""
                    }
                    onLoaded: Qt.callLater(root.focusContent)
                }
            }

            // Keyboard hints
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 22
                color: "transparent"

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Common.Appearance.colors.border
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Common.Appearance.spacing.medium
                    anchors.rightMargin: Common.Appearance.spacing.medium
                    spacing: Common.Appearance.spacing.large

                    Repeater {
                        model: {
                            const hints = [
                                { key: "Tab/S-Tab", action: "tabs" },
                                { key: "^1-9", action: "jump" }
                            ]
                            if (root.currentTab === "apps") {
                                hints.push({ key: "^j/^k", action: "move" })
                                hints.push({ key: "Enter", action: "launch" })
                            } else if (root.currentTab === "windows") {
                                hints.push({ key: "M-Tab/j/k", action: "move" })
                                hints.push({ key: "Enter", action: "focus" })
                            }
                            hints.push({ key: "Esc", action: "close" })
                            return hints
                        }

                        delegate: Row {
                            required property var modelData
                            spacing: Common.Appearance.spacing.tiny

                            Rectangle {
                                width: hintKey.implicitWidth + Common.Appearance.spacing.small * 2
                                height: 14
                                radius: Common.Appearance.rounding.tiny
                                color: Common.Appearance.colors.bgVisual
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    id: hintKey
                                    anchors.centerIn: parent
                                    text: modelData.key
                                    font.family: Common.Appearance.fonts.mono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Common.Appearance.colors.cyan
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.action
                                font.family: Common.Appearance.fonts.mono
                                font.pixelSize: 9
                                color: Common.Appearance.colors.fgDark
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
