import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import "../common" as Common
import "../../services" as Services
import "../../" as Root

// Bluetooth settings view for the right sidebar
ColumnLayout {
    id: root
    spacing: Common.Appearance.spacing.large

    // Refresh device list when view opens
    Component.onCompleted: Services.BluetoothStatus.refresh()

    // Clear available devices when view closes
    Component.onDestruction: {
        Services.BluetoothStatus.stopDiscovery()
        Services.BluetoothStatus.clearAvailableDevices()
    }

    // Header with close button
    RowLayout {
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        Text {
            Layout.fillWidth: true
            text: "Bluetooth"
            font.family: Common.Appearance.fonts.main
            font.pixelSize: Common.Appearance.fontSize.headline
            font.weight: Font.Medium
            color: Common.Appearance.m3colors.onSurface
        }

        MouseArea {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: Root.GlobalStates.sidebarRightOpen = false

            Rectangle {
                anchors.fill: parent
                radius: Common.Appearance.rounding.small
                color: parent.containsMouse ? Common.Appearance.m3colors.surfaceVariant : "transparent"
            }

            Common.Icon {
                anchors.centerIn: parent
                name: Common.Icons.icons.close
                size: Common.Appearance.sizes.iconMedium
                color: Common.Appearance.m3colors.onSurface
            }
        }
    }

    // Power toggle
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 56
        radius: Common.Appearance.rounding.large
        color: Common.Appearance.m3colors.surfaceVariant

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Common.Appearance.spacing.medium
            anchors.rightMargin: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            Common.Icon {
                name: Common.Icons.icons.bluetooth
                size: Common.Appearance.sizes.iconLarge
                color: Services.BluetoothStatus.powered
                    ? Common.Appearance.m3colors.primary
                    : Common.Appearance.m3colors.onSurfaceVariant
            }

            ColumnLayout {
                spacing: 2

                Text {
                    text: "Bluetooth"
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.normal
                    font.weight: Font.Medium
                    color: Common.Appearance.m3colors.onSurface
                }

                Text {
                    text: Services.BluetoothStatus.powered
                        ? (Services.BluetoothStatus.connected
                            ? "Connected to " + Services.BluetoothStatus.connectedDeviceName
                            : "On")
                        : "Off"
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Common.Appearance.m3colors.onSurfaceVariant
                }
            }

            Item { Layout.fillWidth: true }

            // Modern rounded switch
            MouseArea {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignRight
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.BluetoothStatus.setPower(!Services.BluetoothStatus.powered)

                Rectangle {
                    id: btSwitchTrack
                    anchors.fill: parent
                    radius: height / 2
                    color: Services.BluetoothStatus.powered
                        ? Common.Appearance.m3colors.primary
                        : Common.Appearance.m3colors.surfaceVariant
                    border.width: Services.BluetoothStatus.powered ? 0 : 2
                    border.color: Common.Appearance.m3colors.outline

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Rectangle {
                        id: btSwitchThumb
                        width: Services.BluetoothStatus.powered ? 24 : 16
                        height: Services.BluetoothStatus.powered ? 24 : 16
                        radius: height / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: Services.BluetoothStatus.powered ? parent.width - width - 4 : 4
                        color: Services.BluetoothStatus.powered
                            ? Common.Appearance.m3colors.onPrimary
                            : Common.Appearance.m3colors.outline

                        Behavior on x {
                            NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                        }
                        Behavior on width {
                            NumberAnimation { duration: 150 }
                        }
                        Behavior on height {
                            NumberAnimation { duration: 150 }
                        }
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }
            }
        }
    }

    // ===== SECTION 1: Known/Paired Devices =====
    ColumnLayout {
        visible: Services.BluetoothStatus.powered
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        // Section header
        Text {
            text: "My Devices"
            font.family: Common.Appearance.fonts.main
            font.pixelSize: Common.Appearance.fontSize.small
            font.weight: Font.Medium
            color: Common.Appearance.m3colors.onSurfaceVariant
        }

        // Paired devices list
        Rectangle {
            visible: Services.BluetoothStatus.devices.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: pairedDevicesColumn.implicitHeight + Common.Appearance.spacing.medium * 2
            radius: Common.Appearance.rounding.large
            color: Common.Appearance.m3colors.surfaceVariant

            ColumnLayout {
                id: pairedDevicesColumn
                anchors.fill: parent
                anchors.margins: Common.Appearance.spacing.medium
                spacing: Common.Appearance.spacing.small

                Repeater {
                    model: Services.BluetoothStatus.devices

                    delegate: PairedDeviceItem {
                        Layout.fillWidth: true
                        deviceName: modelData.name
                        deviceMac: modelData.mac
                        isConnected: modelData.status === "connected"
                        onConnectClicked: Services.BluetoothStatus.connectDevice(modelData.mac)
                        onDisconnectClicked: Services.BluetoothStatus.disconnectDevice(modelData.mac)
                        onRemoveClicked: Services.BluetoothStatus.forgetDevice(modelData.mac)
                    }
                }
            }
        }

        // No paired devices message
        Rectangle {
            visible: Services.BluetoothStatus.devices.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            radius: Common.Appearance.rounding.large
            color: Common.Appearance.m3colors.surfaceVariant

            Text {
                anchors.centerIn: parent
                text: "No paired devices"
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.normal
                color: Common.Appearance.m3colors.onSurfaceVariant
            }
        }
    }

    // ===== SECTION 2: Available/Discoverable Devices =====
    ColumnLayout {
        visible: Services.BluetoothStatus.powered
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        // Section header with scan button
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Available Devices"
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.small
                font.weight: Font.Medium
                color: Common.Appearance.m3colors.onSurfaceVariant
            }

            Item { Layout.fillWidth: true }

            MouseArea {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    if (Services.BluetoothStatus.discovering) {
                        Services.BluetoothStatus.stopDiscovery()
                    } else {
                        Services.BluetoothStatus.startDiscovery()
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Common.Appearance.rounding.small
                    color: parent.containsMouse ? Common.Appearance.m3colors.surfaceVariant : "transparent"
                }

                Common.Icon {
                    id: refreshIcon
                    anchors.centerIn: parent
                    name: Common.Icons.icons.refresh
                    size: Common.Appearance.sizes.iconSmall
                    color: Services.BluetoothStatus.discovering
                        ? Common.Appearance.m3colors.primary
                        : Common.Appearance.m3colors.onSurfaceVariant

                    RotationAnimation on rotation {
                        running: Services.BluetoothStatus.discovering
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                    }
                }
            }
        }

        // Scanning state
        Rectangle {
            visible: Services.BluetoothStatus.discovering && Services.BluetoothStatus.availableDevices.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            radius: Common.Appearance.rounding.large
            color: Common.Appearance.m3colors.surfaceVariant

            Text {
                anchors.centerIn: parent
                text: "Scanning for devices..."
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.normal
                color: Common.Appearance.m3colors.onSurfaceVariant
            }
        }

        // Available devices list (only shown when discovering or has results)
        Rectangle {
            visible: Services.BluetoothStatus.availableDevices.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: availableDevicesColumn.implicitHeight + Common.Appearance.spacing.medium * 2
            radius: Common.Appearance.rounding.large
            color: Common.Appearance.m3colors.surfaceVariant

            ColumnLayout {
                id: availableDevicesColumn
                anchors.fill: parent
                anchors.margins: Common.Appearance.spacing.medium
                spacing: Common.Appearance.spacing.small

                Repeater {
                    model: Services.BluetoothStatus.availableDevices

                    delegate: AvailableDeviceItem {
                        Layout.fillWidth: true
                        deviceName: modelData.name
                        deviceMac: modelData.mac
                        onPairClicked: Services.BluetoothStatus.pairDevice(modelData.mac)
                    }
                }
            }
        }

        // Idle state - prompt to scan
        Rectangle {
            visible: !Services.BluetoothStatus.discovering && Services.BluetoothStatus.availableDevices.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            radius: Common.Appearance.rounding.large
            color: Common.Appearance.m3colors.surfaceVariant

            Text {
                anchors.centerIn: parent
                text: "Tap refresh to scan"
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.normal
                color: Common.Appearance.m3colors.onSurfaceVariant
            }
        }
    }

    // Spacer
    Item { Layout.fillHeight: true }

    // ===== Paired Device Item Component =====
    component PairedDeviceItem: MouseArea {
        id: pairedItem
        property string deviceName: ""
        property string deviceMac: ""
        property bool isConnected: false

        signal connectClicked()
        signal disconnectClicked()
        signal removeClicked()

        implicitHeight: 48
        hoverEnabled: true

        Rectangle {
            anchors.fill: parent
            radius: Common.Appearance.rounding.medium
            color: pairedItem.containsMouse ? Common.Appearance.surfaceLayer(2) : "transparent"
        }

        RowLayout {
            anchors.fill: parent
            spacing: Common.Appearance.spacing.medium

            // Device icon
            Common.Icon {
                name: pairedItem.isConnected
                    ? Common.Icons.icons.bluetoothConnected
                    : Common.Icons.icons.bluetooth
                size: Common.Appearance.sizes.iconMedium
                color: pairedItem.isConnected
                    ? Common.Appearance.m3colors.primary
                    : Common.Appearance.m3colors.onSurfaceVariant
            }

            // Device info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: pairedItem.deviceName || pairedItem.deviceMac
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.normal
                    color: Common.Appearance.m3colors.onSurface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: pairedItem.isConnected ? "Connected" : "Not connected"
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: pairedItem.isConnected
                        ? Common.Appearance.m3colors.primary
                        : Common.Appearance.m3colors.onSurfaceVariant
                }
            }

            // Action buttons (visible on hover)
            RowLayout {
                visible: pairedItem.containsMouse
                spacing: Common.Appearance.spacing.tiny

                // Connect/Disconnect button
                MouseArea {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (pairedItem.isConnected) {
                            pairedItem.disconnectClicked()
                        } else {
                            pairedItem.connectClicked()
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Common.Appearance.rounding.small
                        color: parent.containsMouse
                            ? Common.Appearance.m3colors.primaryContainer
                            : "transparent"
                    }

                    Common.Icon {
                        anchors.centerIn: parent
                        name: pairedItem.isConnected
                            ? Common.Icons.icons.close
                            : Common.Icons.icons.bluetooth
                        size: Common.Appearance.sizes.iconSmall
                        color: Common.Appearance.m3colors.onSurface
                    }
                }

                // Remove/Forget button
                MouseArea {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pairedItem.removeClicked()

                    Rectangle {
                        anchors.fill: parent
                        radius: Common.Appearance.rounding.small
                        color: parent.containsMouse
                            ? Common.Appearance.m3colors.errorContainer
                            : "transparent"
                    }

                    Common.Icon {
                        anchors.centerIn: parent
                        name: Common.Icons.icons.delete
                        size: Common.Appearance.sizes.iconSmall
                        color: parent.containsMouse
                            ? Common.Appearance.m3colors.onErrorContainer
                            : Common.Appearance.m3colors.onSurfaceVariant
                    }
                }
            }
        }
    }

    // ===== Available Device Item Component =====
    component AvailableDeviceItem: MouseArea {
        id: availableItem
        property string deviceName: ""
        property string deviceMac: ""

        signal pairClicked()

        implicitHeight: 48
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: pairClicked()

        Rectangle {
            anchors.fill: parent
            radius: Common.Appearance.rounding.medium
            color: availableItem.containsMouse ? Common.Appearance.surfaceLayer(2) : "transparent"
        }

        RowLayout {
            anchors.fill: parent
            spacing: Common.Appearance.spacing.medium

            // Device icon
            Common.Icon {
                name: Common.Icons.icons.bluetooth
                size: Common.Appearance.sizes.iconMedium
                color: Common.Appearance.m3colors.onSurfaceVariant
            }

            // Device info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: availableItem.deviceName || availableItem.deviceMac
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.normal
                    color: Common.Appearance.m3colors.onSurface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: "Tap to pair"
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Common.Appearance.m3colors.onSurfaceVariant
                }
            }
        }
    }
}
