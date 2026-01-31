import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import "../common" as Common
import "../../services" as Services
import "../../" as Root

// Bluetooth settings view - TUI style
ColumnLayout {
    id: root
    spacing: Common.Appearance.spacing.medium
    anchors.topMargin: 5
    anchors.bottomMargin: 5

    Component.onCompleted: Services.BluetoothStatus.refresh()

    Component.onDestruction: {
        Services.BluetoothStatus.stopDiscovery()
        Services.BluetoothStatus.clearAvailableDevices()
    }

    // Header
    Text {
        Layout.fillWidth: true
        text: "Bluetooth"
        font.family: Common.Appearance.fonts.mono
        font.pixelSize: Common.Appearance.fontSize.large
        font.bold: true
        color: Common.Appearance.colors.fg
    }

    // Power toggle
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: btContent.height + Common.Appearance.spacing.medium * 2
        color: Common.Appearance.colors.bgDark
        border.width: 1
        border.color: Common.Appearance.colors.border
        radius: Common.Appearance.rounding.tiny

        RowLayout {
            id: btContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            Common.Icon {
                name: {
                    if (Services.BluetoothStatus.connected) return Common.Icons.icons.bluetoothConnected
                    if (Services.BluetoothStatus.powered) return Common.Icons.icons.bluetooth
                    return Common.Icons.icons.bluetoothOff
                }
                size: 20
                color: Services.BluetoothStatus.connected
                    ? Common.Appearance.colors.cyan
                    : (Services.BluetoothStatus.powered
                        ? Common.Appearance.colors.fg
                        : Common.Appearance.colors.fgDark)
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: "Bluetooth"
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.normal
                    font.bold: true
                    color: Common.Appearance.colors.fg
                }

                Text {
                    text: Services.BluetoothStatus.powered
                        ? (Services.BluetoothStatus.connected
                            ? "[Connected] " + Services.BluetoothStatus.connectedDeviceName
                            : "[ON]")
                        : "[OFF]"
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Services.BluetoothStatus.connected
                        ? Common.Appearance.colors.cyan
                        : (Services.BluetoothStatus.powered
                            ? Common.Appearance.colors.green
                            : Common.Appearance.colors.fgDark)
                }
            }

            Common.TuiToggle {
                checked: Services.BluetoothStatus.powered
                onToggled: Services.BluetoothStatus.setPower(!Services.BluetoothStatus.powered)
            }
        }
    }

    // My Devices section
    ColumnLayout {
        visible: Services.BluetoothStatus.powered
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        Text {
            text: "My Devices"
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.small
            font.bold: true
            color: Common.Appearance.colors.fgDark
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: myDevicesContent.height + Common.Appearance.spacing.small * 2
            color: Common.Appearance.colors.bgDark
            border.width: 1
            border.color: Common.Appearance.colors.border
            radius: Common.Appearance.rounding.tiny

            ColumnLayout {
                id: myDevicesContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Common.Appearance.spacing.small
                spacing: 0

                // Empty state
                Text {
                    visible: Services.BluetoothStatus.devices.length === 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "-- No paired devices --"
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Common.Appearance.colors.comment
                }

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
    }

    // Available Devices section
    ColumnLayout {
        visible: Services.BluetoothStatus.powered
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "Available Devices"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                font.bold: true
                color: Common.Appearance.colors.fgDark
            }

            Common.TuiButton {
                icon: Common.Icons.icons.refresh
                onClicked: {
                    if (Services.BluetoothStatus.discovering) {
                        Services.BluetoothStatus.stopDiscovery()
                    } else {
                        Services.BluetoothStatus.startDiscovery()
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: availableContent.height + Common.Appearance.spacing.small * 2
            color: Common.Appearance.colors.bgDark
            border.width: 1
            border.color: Common.Appearance.colors.border
            radius: Common.Appearance.rounding.tiny

            ColumnLayout {
                id: availableContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Common.Appearance.spacing.small
                spacing: 0

                // Scanning state
                Text {
                    visible: Services.BluetoothStatus.discovering && Services.BluetoothStatus.availableDevices.length === 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "[Scanning...]"
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Common.Appearance.colors.cyan
                }

                // Idle state
                Text {
                    visible: !Services.BluetoothStatus.discovering && Services.BluetoothStatus.availableDevices.length === 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "-- Tap refresh to scan --"
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Common.Appearance.colors.comment
                }

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
    }

    // Spacer
    Item { Layout.fillHeight: true }

    // Paired Device Item Component
    component PairedDeviceItem: Rectangle {
        id: pairedItem
        property string deviceName: ""
        property string deviceMac: ""
        property bool isConnected: false

        signal connectClicked()
        signal disconnectClicked()
        signal removeClicked()

        Layout.fillWidth: true
        height: 32
        color: pairedMouse.containsMouse
            ? Common.Appearance.colors.bgHighlight
            : (isConnected ? Common.Appearance.colors.bgVisual : "transparent")

        MouseArea {
            id: pairedMouse
            anchors.fill: parent
            hoverEnabled: true
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Common.Appearance.spacing.medium
            anchors.rightMargin: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.small

            Text {
                Layout.fillWidth: true
                text: deviceName || deviceMac
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.normal
                color: Common.Appearance.colors.fg
                elide: Text.ElideRight
            }

            Text {
                text: isConnected ? "[Connected]" : "[Paired]"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                font.bold: true
                color: isConnected ? Common.Appearance.colors.cyan : Common.Appearance.colors.fgDark
            }

            Common.TuiButton {
                icon: isConnected ? Common.Icons.icons.close : Common.Icons.icons.refresh
                onClicked: isConnected ? disconnectClicked() : connectClicked()
            }

            Common.TuiButton {
                icon: Common.Icons.icons.remove
                danger: true
                onClicked: removeClicked()
            }
        }
    }

    // Available Device Item Component
    component AvailableDeviceItem: Rectangle {
        id: availableItem
        property string deviceName: ""
        property string deviceMac: ""

        signal pairClicked()

        Layout.fillWidth: true
        height: 32
        color: availableMouse.containsMouse ? Common.Appearance.colors.bgHighlight : "transparent"

        MouseArea {
            id: availableMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pairClicked()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Common.Appearance.spacing.medium
            anchors.rightMargin: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.small

            Text {
                Layout.fillWidth: true
                text: deviceName || deviceMac
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.normal
                color: Common.Appearance.colors.fg
                elide: Text.ElideRight
            }

            Text {
                text: "Tap to pair"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.colors.comment
            }
        }
    }
}
