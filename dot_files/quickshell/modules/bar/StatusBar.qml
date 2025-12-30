import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

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

    // Bar button component
    component BarButton: MouseArea {
        id: button

        property string icon: ""
        property string buttonText: ""
        property string tooltip: ""
        property bool highlighted: false
        property color textColor: Common.Appearance.m3colors.onSurface

        Layout.preferredHeight: 28
        Layout.preferredWidth: Math.max(buttonContent.implicitWidth + Common.Appearance.spacing.medium * 2, 28)

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: Common.Appearance.rounding.small
            color: button.highlighted
                ? Common.Appearance.m3colors.primaryContainer
                : (button.containsMouse
                    ? Common.Appearance.m3colors.surfaceVariant
                    : "transparent")

            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }

        RowLayout {
            id: buttonContent
            anchors.centerIn: parent
            spacing: Common.Appearance.spacing.tiny

            Text {
                visible: button.icon !== ""
                text: button.icon
                font.family: Common.Appearance.fonts.icon
                font.pixelSize: Common.Appearance.sizes.iconMedium
                color: button.highlighted
                    ? Common.Appearance.m3colors.onPrimaryContainer
                    : button.textColor
            }

            Text {
                visible: button.buttonText !== ""
                text: button.buttonText
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.normal
                color: button.highlighted
                    ? Common.Appearance.m3colors.onPrimaryContainer
                    : button.textColor
            }
        }
    }

    // Bar indicator (icon only, no interaction)
    component BarIndicator: Item {
        property string icon: ""
        property string tooltip: ""
        property color iconColor: Common.Appearance.m3colors.onSurface

        Layout.preferredHeight: 28
        Layout.preferredWidth: 28

        Text {
            anchors.centerIn: parent
            text: parent.icon
            font.family: Common.Appearance.fonts.icon
            font.pixelSize: Common.Appearance.sizes.iconMedium
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

        // Bottom border
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Common.Appearance.m3colors.outlineVariant
        }
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
            onClicked: Root.GlobalStates.toggleSidebarLeft(root.targetScreen)
        }

        // Spacer
        Item { Layout.fillWidth: true }

        // Right section - System indicators (only on rightmost screen)
        RowLayout {
            visible: root.isRightmost
            spacing: Common.Appearance.spacing.tiny

            // Weather (if enabled)
            BarButton {
                visible: Common.Config.showWeather && Services.Weather.ready
                icon: Common.Icons.weatherIcon(Services.Weather.condition, Services.Weather.isNight)
                buttonText: Services.Weather.temperature
                tooltip: Services.Weather.description
            }

            // Privacy indicators
            BarIndicator {
                visible: Services.Privacy.micInUse
                icon: Common.Icons.icons.mic
                iconColor: Common.Appearance.m3colors.error
                tooltip: "Microphone in use"
            }

            BarIndicator {
                visible: Services.Privacy.cameraInUse
                icon: Common.Icons.icons.camera
                iconColor: Common.Appearance.m3colors.error
                tooltip: "Camera in use"
            }

            // Network - only show if wifi available (for wifi) or ethernet connected
            BarIndicator {
                visible: Common.Config.showNetwork && (Services.Network.wifiAvailable || (Services.Network.connected && Services.Network.type === "ethernet"))
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
            }

            // Bluetooth
            BarIndicator {
                visible: Services.BluetoothStatus.available && Services.BluetoothStatus.powered
                icon: Services.BluetoothStatus.connected
                    ? Common.Icons.icons.bluetoothConnected
                    : Common.Icons.icons.bluetooth
                tooltip: Services.BluetoothStatus.connected
                    ? "Bluetooth: Connected"
                    : "Bluetooth: On"
            }

            // Battery (if present)
            BarButton {
                visible: Common.Config.showBattery && Services.Battery.present
                icon: Common.Icons.batteryIcon(Services.Battery.percent, Services.Battery.charging)
                buttonText: Services.Battery.percent + "%"
                tooltip: Services.Battery.charging
                    ? "Charging: " + Services.Battery.percent + "%"
                    : "Battery: " + Services.Battery.percent + "%"
                textColor: Services.Battery.percent <= 20 && !Services.Battery.charging
                    ? Common.Appearance.m3colors.error
                    : Common.Appearance.m3colors.onSurface
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
                onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen)
                textColor: Root.GlobalStates.doNotDisturb
                    ? Common.Appearance.m3colors.onSurfaceVariant
                    : (Root.GlobalStates.unreadNotificationCount > 0
                        ? Common.Appearance.m3colors.onSurface
                        : Common.Appearance.m3colors.onSurfaceVariant)
            }

            // Date and Time - rightmost item
            BarButton {
                id: clockButton
                buttonText: Services.DateTime.dateString + "  " + Services.DateTime.timeString
                tooltip: "Click to open calendar"
                onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen)

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: Services.DateTime.update()
                }
            }
        }
    }
}
