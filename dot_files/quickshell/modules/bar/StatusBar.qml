import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray

import "../common" as Common
import "../../services" as Services
import "../../" as Root

PanelWindow {
    id: root

    required property var targetScreen
    screen: targetScreen

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Common.Appearance.sizes.barHeight
    color: "transparent"

    // Bar should be above click catchers so it's always clickable
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "statusbar"

    // Bar button component
    component BarButton: MouseArea {
        id: button

        property string icon: ""
        property string buttonText: ""
        property string tooltip: ""
        property bool highlighted: false
        property color textColor: Common.Appearance.m3colors.onSurfaceVariant

        Layout.preferredHeight: 28
        // Icon-only buttons get minimal padding, buttons with text get more
        Layout.preferredWidth: button.buttonText === ""
            ? 28
            : buttonContent.implicitWidth + Common.Appearance.spacing.small * 2

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: Common.Appearance.rounding.small
            color: button.containsMouse
                ? Common.Appearance.m3colors.surfaceVariant
                : "transparent"

            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }

        RowLayout {
            id: buttonContent
            anchors.centerIn: parent
            spacing: Common.Appearance.spacing.tiny

            Common.Icon {
                visible: button.icon !== ""
                name: button.icon
                size: Common.Appearance.sizes.iconMedium
                color: button.highlighted
                    ? Common.Appearance.m3colors.primary
                    : button.textColor
            }

            Text {
                visible: button.buttonText !== ""
                text: button.buttonText
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.normal
                color: button.highlighted
                    ? Common.Appearance.m3colors.primary
                    : button.textColor
            }
        }
    }

    // Bar indicator (icon only, no interaction)
    component BarIndicator: Item {
        property string icon: ""
        property string tooltip: ""
        property color iconColor: Common.Appearance.m3colors.onSurfaceVariant

        Layout.preferredHeight: 28
        Layout.preferredWidth: 28

        Common.Icon {
            anchors.centerIn: parent
            name: parent.icon
            size: Common.Appearance.sizes.iconMedium
            color: parent.iconColor
        }
    }

    // Bar background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(
            Common.Appearance.m3colors.surface.r,
            Common.Appearance.m3colors.surface.g,
            Common.Appearance.m3colors.surface.b,
            Common.Appearance.panelOpacity
        )

    }

    // Helper properties for screen position (reactive to screen changes)
    property bool isLeftmost: {
        // Single monitor case
        if (Quickshell.screens.length === 1) return true
        // Multi-monitor: check against leftmost screen
        return targetScreen === Root.GlobalStates.leftmostScreen
    }
    property bool isRightmost: {
        // Single monitor case
        if (Quickshell.screens.length === 1) return true
        // Multi-monitor: check against rightmost screen
        return targetScreen === Root.GlobalStates.rightmostScreen
    }

    // Bar content
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Common.Appearance.spacing.medium
        anchors.rightMargin: Common.Appearance.spacing.medium
        spacing: Common.Appearance.spacing.small

        // Left section - Launcher button (only on leftmost screen)
        BarButton {
            visible: root.isLeftmost
            icon: Common.Icons.icons.apps
            tooltip: "Applications"
            onClicked: Root.GlobalStates.toggleSidebarLeft(root.targetScreen, "apps")
        }

        // Updates button (only on leftmost screen, shows indicator when attention needed)
        MouseArea {
            id: updatesButton
            visible: root.isLeftmost
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Root.GlobalStates.toggleSidebarLeft(root.targetScreen, "updates")

            property bool isRunning: Services.Updates.preinstallRunning
            property bool needsAttention: Services.Updates.needsAttention

            Rectangle {
                anchors.fill: parent
                radius: Common.Appearance.rounding.small
                color: updatesButton.containsMouse
                    ? Common.Appearance.m3colors.surfaceVariant
                    : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            Common.Icon {
                anchors.centerIn: parent
                name: updatesButton.isRunning
                    ? Common.Icons.icons.refresh
                    : (updatesButton.needsAttention
                        ? Common.Icons.icons.download
                        : Common.Icons.icons.checkCircle)
                size: Common.Appearance.sizes.iconMedium
                color: updatesButton.needsAttention
                    ? Common.Appearance.m3colors.primary
                    : Common.Appearance.m3colors.onSurfaceVariant

                RotationAnimation on rotation {
                    running: updatesButton.isRunning
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }
        }

        // Spacer
        Item { Layout.fillWidth: true }

        // Right section - System indicators (only on rightmost screen)
        RowLayout {
            visible: root.isRightmost
            spacing: 2

            // System tray icons
            Repeater {
                model: SystemTray.items

                delegate: MouseArea {
                    id: trayItemArea
                    required property var modelData

                    Layout.preferredHeight: 28
                    Layout.preferredWidth: 28
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    // Check if icon has unsupported custom path (e.g. "icon_name?path=/some/path")
                    property bool hasCustomPath: modelData.icon && modelData.icon.includes("?path=")

                    // Resolve icon source - handle paths, icon names, skip unsupported custom paths
                    property string iconSource: {
                        const icon = modelData.icon
                        if (!icon || icon === "") return ""
                        // Skip icons with custom paths - Quickshell doesn't support them
                        if (icon.includes("?path=")) return ""
                        // Already a full path or URL
                        if (icon.startsWith("/")) return "file://" + icon
                        if (icon.startsWith("file://") || icon.startsWith("image://")) return icon
                        // Icon name - try Qt icon provider
                        return "image://icon/" + icon
                    }

                    // Datacube fallback lookup using app title
                    property string datacubeIcon: Services.IconResolver.getIcon(modelData.title)

                    Rectangle {
                        anchors.fill: parent
                        radius: Common.Appearance.rounding.small
                        color: trayItemArea.containsMouse
                            ? Common.Appearance.m3colors.surfaceVariant
                            : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    // Track if primary icon failed (Error, Null status, or has unsupported custom path)
                    property bool primaryFailed: trayItemArea.hasCustomPath || primaryTrayIcon.status === Image.Error || primaryTrayIcon.status === Image.Null || trayItemArea.iconSource === ""

                    // Primary icon from tray item
                    Image {
                        id: primaryTrayIcon
                        anchors.centerIn: parent
                        width: Common.Appearance.sizes.iconMedium
                        height: Common.Appearance.sizes.iconMedium
                        sourceSize: Qt.size(Common.Appearance.sizes.iconMedium, Common.Appearance.sizes.iconMedium)
                        source: trayItemArea.iconSource
                        smooth: true
                        visible: status === Image.Ready
                    }

                    // Datacube fallback icon
                    Image {
                        id: fallbackTrayIcon
                        anchors.centerIn: parent
                        width: Common.Appearance.sizes.iconMedium
                        height: Common.Appearance.sizes.iconMedium
                        sourceSize: Qt.size(Common.Appearance.sizes.iconMedium, Common.Appearance.sizes.iconMedium)
                        source: trayItemArea.primaryFailed ? trayItemArea.datacubeIcon : ""
                        smooth: true
                        visible: trayItemArea.primaryFailed && status === Image.Ready
                    }

                    // Last resort: letter icon
                    Rectangle {
                        anchors.centerIn: parent
                        width: Common.Appearance.sizes.iconMedium
                        height: Common.Appearance.sizes.iconMedium
                        radius: Common.Appearance.rounding.small
                        color: Common.Appearance.m3colors.primaryContainer
                        visible: trayItemArea.primaryFailed && fallbackTrayIcon.status !== Image.Ready

                        Text {
                            anchors.centerIn: parent
                            text: trayItemArea.modelData.title ? trayItemArea.modelData.title.charAt(0).toUpperCase() : "?"
                            font.pixelSize: 10
                            font.bold: true
                            color: Common.Appearance.m3colors.onPrimaryContainer
                        }
                    }

                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton || (trayItemArea.modelData.onlyMenu && trayItemArea.modelData.hasMenu)) {
                            // Right click or menu-only item: show menu
                            if (trayItemArea.modelData.hasMenu) {
                                // Map coordinates to window
                                const pos = trayItemArea.mapToItem(null, 0, trayItemArea.height)
                                trayItemArea.modelData.display(root, pos.x, pos.y)
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            trayItemArea.modelData.secondaryActivate()
                        } else {
                            // Left click: activate
                            trayItemArea.modelData.activate()
                        }
                    }

                    onWheel: (wheel) => {
                        trayItemArea.modelData.scroll(wheel.angleDelta.y, false)
                    }
                }
            }

            // Camera Privacy indicator
            BarButton {
                visible: Services.Privacy.cameraInUse
                icon: Common.Icons.icons.camera
                textColor: Common.Appearance.m3colors.error
                tooltip: "Camera in use"
            }

            // Audio (mic + output combined)
            MouseArea {
                id: audioButton
                Layout.preferredHeight: 28
                Layout.preferredWidth: 56  // Two 28px icons
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "audio")

                Rectangle {
                    anchors.fill: parent
                    radius: Common.Appearance.rounding.small
                    color: audioButton.containsMouse
                        ? Common.Appearance.m3colors.surfaceVariant
                        : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }

                RowLayout {
                    id: audioButtonContent
                    anchors.fill: parent
                    spacing: 0

                    Item {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28

                        Common.Icon {
                            anchors.centerIn: parent
                            name: Services.Audio.micMuted
                                ? Common.Icons.icons.micOff
                                : Common.Icons.icons.mic
                            size: Common.Appearance.sizes.iconMedium
                            color: Services.Privacy.micInUse
                                ? Common.Appearance.m3colors.error
                                : Common.Appearance.m3colors.onSurfaceVariant
                        }
                    }

                    Item {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28

                        Common.Icon {
                            anchors.centerIn: parent
                            name: Services.Audio.muted
                                ? Common.Icons.icons.volumeOff
                                : Common.Icons.volumeIcon(Services.Audio.volume * 100, false)
                            size: Common.Appearance.sizes.iconMedium
                            color: Common.Appearance.m3colors.onSurfaceVariant
                        }
                    }
                }
            }

            // Bluetooth
            BarButton {
                visible: Services.BluetoothStatus.available
                icon: Services.BluetoothStatus.powered
                    ? (Services.BluetoothStatus.connected
                        ? Common.Icons.icons.bluetoothConnected
                        : Common.Icons.icons.bluetooth)
                    : Common.Icons.icons.bluetoothOff
                tooltip: Services.BluetoothStatus.powered
                    ? (Services.BluetoothStatus.connected
                        ? "Bluetooth: " + Services.BluetoothStatus.connectedDeviceName
                        : "Bluetooth: On")
                    : "Bluetooth: Off"
                textColor: Services.BluetoothStatus.connected
                    ? Common.Appearance.m3colors.primary
                    : Common.Appearance.m3colors.onSurfaceVariant
                onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "bluetooth")
            }

            // Network
            BarButton {
                visible: Common.Config.showNetwork
                icon: {
                    if (!Services.Network.connected) {
                        return Services.Network.wifiAvailable ? Common.Icons.icons.wifiOff : Common.Icons.icons.ethernetOff
                    }
                    if (Services.Network.type === "wifi") {
                        return Common.Icons.wifiIcon(Services.Network.strength, true)
                    }
                    return Common.Icons.icons.ethernet
                }
                tooltip: Services.Network.connected
                    ? Services.Network.name
                    : "Disconnected"
                onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "network")
            }

            // Notifications bell
            BarButton {
                icon: Root.GlobalStates.doNotDisturb
                    ? Common.Icons.icons.doNotDisturb
                    : Common.Icons.icons.notification
                tooltip: Root.GlobalStates.doNotDisturb
                    ? "Do Not Disturb"
                    : (Root.GlobalStates.unreadNotificationCount > 0
                        ? Root.GlobalStates.unreadNotificationCount + " notifications"
                        : "Notifications")
                onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "notifications")
                textColor: Root.GlobalStates.unreadNotificationCount > 0 && !Root.GlobalStates.doNotDisturb
                    ? Common.Appearance.m3colors.orange
                    : Common.Appearance.m3colors.onSurfaceVariant
            }

            // Calendar / Date-Time
            BarButton {
                id: clockButton
                icon: Common.Icons.icons.calendar
                buttonText: Services.DateTime.shortDateString + " " + Services.DateTime.timeString
                tooltip: Services.DateTime.fullDateTimeString

                onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "calendar")

                // Show tooltip OSD on hover
                onContainsMouseChanged: {
                    if (containsMouse) {
                        Root.GlobalStates.osdType = "tooltip"
                        Root.GlobalStates.osdTooltipText = Services.DateTime.fullDateTimeString
                        Root.GlobalStates.osdVisible = true
                    } else {
                        if (Root.GlobalStates.osdType === "tooltip") {
                            Root.GlobalStates.osdVisible = false
                        }
                    }
                }

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: Services.DateTime.update()
                }
            }

            // Weather (if enabled)
            BarButton {
                visible: Common.Config.showWeather
                icon: Services.Weather.ready
                    ? Common.Icons.weatherIcon(Services.Weather.condition, Services.Weather.isNight)
                    : Common.Icons.icons.cloudy
                buttonText: Services.Weather.ready ? Services.Weather.temperature : "--°"
                tooltip: Services.Weather.ready ? Services.Weather.description : "Loading weather..."
                onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "weather")
            }

            // Power button (shows battery on laptops, power icon on desktops)
            BarButton {
                icon: {
                    if (Services.Battery.present) {
                        // Laptop with battery
                        if (Services.Battery.pluggedIn && Services.Battery.percent >= 95) {
                            // Fully charged and plugged in
                            return Common.Icons.icons.plug
                        } else if (Services.Battery.charging) {
                            return Common.Icons.icons.batteryCharging
                        } else {
                            return Common.Icons.batteryIcon(Services.Battery.percent, false)
                        }
                    }
                    // Desktop - no battery
                    return Common.Icons.icons.power
                }
                buttonText: Services.Battery.present ? Services.Battery.percent + "%" : ""
                tooltip: {
                    if (Services.Battery.present) {
                        if (Services.Battery.pluggedIn && Services.Battery.percent >= 95) {
                            return "Fully charged"
                        } else if (Services.Battery.charging) {
                            return "Charging: " + Services.Battery.percent + "%"
                        } else {
                            const timeStr = Services.Battery.timeRemainingString()
                            return "Battery: " + Services.Battery.percent + "%" + (timeStr ? " (" + timeStr + " remaining)" : "")
                        }
                    }
                    return "Power options"
                }
                textColor: {
                    if (Services.Battery.present) {
                        if (Services.Battery.percent <= 20 && !Services.Battery.charging) {
                            return Common.Appearance.m3colors.error
                        }
                        if (Services.Battery.pluggedIn) {
                            return Common.Appearance.m3colors.primary
                        }
                    }
                    return Common.Appearance.m3colors.onSurfaceVariant
                }
                onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "power")
            }
        }
    }
}
