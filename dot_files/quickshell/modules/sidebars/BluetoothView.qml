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

    // Header with back button
    RowLayout {
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        MouseArea {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            cursorShape: Qt.PointingHandCursor
            onClicked: Root.GlobalStates.sidebarRightView = "default"

            Rectangle {
                anchors.fill: parent
                radius: Common.Appearance.rounding.small
                color: parent.containsMouse ? Common.Appearance.m3colors.surfaceVariant : "transparent"
            }

            Text {
                anchors.centerIn: parent
                text: Common.Icons.icons.back
                font.family: Common.Appearance.fonts.icon
                font.pixelSize: Common.Appearance.sizes.iconMedium
                color: Common.Appearance.m3colors.onSurface
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Bluetooth"
            font.family: Common.Appearance.fonts.main
            font.pixelSize: Common.Appearance.fontSize.headline
            font.weight: Font.Medium
            color: Common.Appearance.m3colors.onSurface
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

            Text {
                text: Common.Icons.icons.bluetooth
                font.family: Common.Appearance.fonts.icon
                font.pixelSize: Common.Appearance.sizes.iconLarge
                color: Services.BluetoothStatus.powered
                    ? Common.Appearance.m3colors.primary
                    : Common.Appearance.m3colors.onSurfaceVariant
            }

            ColumnLayout {
                Layout.fillWidth: true
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

            // Modern rounded switch
            MouseArea {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 32
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

    // Scanning indicator / button
    Rectangle {
        visible: Services.BluetoothStatus.powered
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        radius: Common.Appearance.rounding.medium
        color: Services.BluetoothStatus.discovering
            ? Common.Appearance.m3colors.primaryContainer
            : Common.Appearance.m3colors.surfaceVariant

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (Services.BluetoothStatus.discovering) {
                    Services.BluetoothStatus.stopDiscovery()
                } else {
                    Services.BluetoothStatus.startDiscovery()
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Common.Appearance.spacing.medium
                anchors.rightMargin: Common.Appearance.spacing.medium
                spacing: Common.Appearance.spacing.small

                Text {
                    text: Common.Icons.icons.search
                    font.family: Common.Appearance.fonts.icon
                    font.pixelSize: Common.Appearance.sizes.iconMedium
                    color: Services.BluetoothStatus.discovering
                        ? Common.Appearance.m3colors.onPrimaryContainer
                        : Common.Appearance.m3colors.onSurfaceVariant

                    RotationAnimation on rotation {
                        running: Services.BluetoothStatus.discovering
                        from: 0
                        to: 360
                        duration: 2000
                        loops: Animation.Infinite
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: Services.BluetoothStatus.discovering ? "Scanning..." : "Scan for devices"
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.normal
                    color: Services.BluetoothStatus.discovering
                        ? Common.Appearance.m3colors.onPrimaryContainer
                        : Common.Appearance.m3colors.onSurface
                }
            }
        }
    }

    // Paired devices section
    ColumnLayout {
        visible: Services.BluetoothStatus.powered && Services.BluetoothStatus.devices.length > 0
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        Text {
            text: "Paired Devices"
            font.family: Common.Appearance.fonts.main
            font.pixelSize: Common.Appearance.fontSize.small
            font.weight: Font.Medium
            color: Common.Appearance.m3colors.onSurfaceVariant
        }

        Rectangle {
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

                    delegate: DeviceItem {
                        Layout.fillWidth: true
                        deviceName: modelData.name
                        deviceMac: modelData.mac
                        isConnected: modelData.status === "connected"
                        isPaired: true
                        onConnectClicked: Services.BluetoothStatus.connectDevice(modelData.mac)
                        onDisconnectClicked: Services.BluetoothStatus.disconnectDevice(modelData.mac)
                        onForgetClicked: Services.BluetoothStatus.forgetDevice(modelData.mac)
                    }
                }
            }
        }
    }

    // Available devices section
    ColumnLayout {
        visible: Services.BluetoothStatus.powered && Services.BluetoothStatus.discovering && Services.BluetoothStatus.availableDevices.length > 0
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        Text {
            text: "Available Devices"
            font.family: Common.Appearance.fonts.main
            font.pixelSize: Common.Appearance.fontSize.small
            font.weight: Font.Medium
            color: Common.Appearance.m3colors.onSurfaceVariant
        }

        Rectangle {
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

                    delegate: DeviceItem {
                        Layout.fillWidth: true
                        deviceName: modelData.name
                        deviceMac: modelData.mac
                        isConnected: false
                        isPaired: false
                        onConnectClicked: {
                            Services.BluetoothStatus.pairDevice(modelData.mac)
                        }
                    }
                }
            }
        }
    }

    // Empty state when powered but no devices
    Rectangle {
        visible: Services.BluetoothStatus.powered && Services.BluetoothStatus.devices.length === 0 && !Services.BluetoothStatus.discovering
        Layout.fillWidth: true
        Layout.preferredHeight: 100
        radius: Common.Appearance.rounding.large
        color: Common.Appearance.m3colors.surfaceVariant

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Common.Appearance.spacing.small

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Common.Icons.icons.bluetoothOff
                font.family: Common.Appearance.fonts.icon
                font.pixelSize: 32
                color: Common.Appearance.m3colors.onSurfaceVariant
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "No paired devices"
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.normal
                color: Common.Appearance.m3colors.onSurfaceVariant
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Tap scan to find devices"
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.m3colors.onSurfaceVariant
            }
        }
    }

    // Spacer
    Item { Layout.fillHeight: true }

    // Device item component
    component DeviceItem: MouseArea {
        id: deviceItem
        property string deviceName: ""
        property string deviceMac: ""
        property bool isConnected: false
        property bool isPaired: false

        signal connectClicked()
        signal disconnectClicked()
        signal forgetClicked()

        implicitHeight: 48
        hoverEnabled: true

        Rectangle {
            anchors.fill: parent
            radius: Common.Appearance.rounding.medium
            color: deviceItem.containsMouse ? Common.Appearance.surfaceLayer(2) : "transparent"
        }

        RowLayout {
            anchors.fill: parent
            spacing: Common.Appearance.spacing.medium

            // Device icon
            Text {
                text: Common.Icons.icons.bluetoothConnected
                font.family: Common.Appearance.fonts.icon
                font.pixelSize: Common.Appearance.sizes.iconMedium
                color: deviceItem.isConnected
                    ? Common.Appearance.m3colors.primary
                    : Common.Appearance.m3colors.onSurfaceVariant
            }

            // Device info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: deviceItem.deviceName || deviceItem.deviceMac
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.normal
                    color: Common.Appearance.m3colors.onSurface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    visible: deviceItem.isConnected || !deviceItem.isPaired
                    text: deviceItem.isConnected ? "Connected" : "Tap to pair"
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: deviceItem.isConnected
                        ? Common.Appearance.m3colors.primary
                        : Common.Appearance.m3colors.onSurfaceVariant
                }
            }

            // Action buttons (visible on hover for paired devices)
            RowLayout {
                visible: deviceItem.containsMouse && deviceItem.isPaired
                spacing: Common.Appearance.spacing.tiny

                // Connect/Disconnect button
                MouseArea {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (deviceItem.isConnected) {
                            deviceItem.disconnectClicked()
                        } else {
                            deviceItem.connectClicked()
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Common.Appearance.rounding.small
                        color: parent.containsMouse
                            ? Common.Appearance.m3colors.primaryContainer
                            : "transparent"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: deviceItem.isConnected
                            ? Common.Icons.icons.close
                            : Common.Icons.icons.bluetooth
                        font.family: Common.Appearance.fonts.icon
                        font.pixelSize: Common.Appearance.sizes.iconSmall
                        color: Common.Appearance.m3colors.onSurface
                    }
                }

                // Forget button
                MouseArea {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    cursorShape: Qt.PointingHandCursor
                    onClicked: deviceItem.forgetClicked()

                    Rectangle {
                        anchors.fill: parent
                        radius: Common.Appearance.rounding.small
                        color: parent.containsMouse
                            ? Common.Appearance.m3colors.errorContainer
                            : "transparent"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Common.Icons.icons.delete
                        font.family: Common.Appearance.fonts.icon
                        font.pixelSize: Common.Appearance.sizes.iconSmall
                        color: parent.parent.containsMouse
                            ? Common.Appearance.m3colors.onErrorContainer
                            : Common.Appearance.m3colors.onSurfaceVariant
                    }
                }
            }
        }

        // Click to connect if not paired
        onClicked: {
            if (!isPaired) {
                connectClicked()
            }
        }
    }
}
