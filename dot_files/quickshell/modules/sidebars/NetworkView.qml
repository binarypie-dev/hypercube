import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import "../common" as Common
import "../../services" as Services
import "../../" as Root

// Network settings view for the right sidebar
ColumnLayout {
    id: root
    spacing: Common.Appearance.spacing.medium

    // Refresh when view opens
    Component.onCompleted: {
        Services.Network.refresh()
        Services.Network.loadSavedNetworks()
    }

    // Stop scanning when view closes
    Component.onDestruction: {
        Services.Network.availableNetworks = []
    }

    // Header with close button
    RowLayout {
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        Text {
            Layout.fillWidth: true
            text: "Network"
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

    // ===== Interface List =====
    Repeater {
        id: interfaceRepeater
        model: ScriptModel {
            values: Services.Network.interfaces
        }

        delegate: Item {
            Layout.fillWidth: true
            Layout.preferredHeight: ifaceCard.implicitHeight

            required property var modelData
            required property int index

            Rectangle {
                id: ifaceCard
                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: ifaceContent.implicitHeight + Common.Appearance.spacing.medium * 2
                radius: Common.Appearance.rounding.large
                color: Common.Appearance.m3colors.surfaceVariant

                property bool isConnected: modelData.state === "connected"
                property bool isWifi: modelData.type === "wifi"
                property bool isEthernet: modelData.type === "ethernet"

            ColumnLayout {
                id: ifaceContent
                anchors.fill: parent
                anchors.margins: Common.Appearance.spacing.medium
                spacing: Common.Appearance.spacing.small

                // Header row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Common.Appearance.spacing.medium

                    Common.Icon {
                        name: ifaceCard.isWifi
                            ? (ifaceCard.isConnected ? Common.Icons.icons.wifi : Common.Icons.icons.wifiOff)
                            : Common.Icons.icons.ethernet
                        size: Common.Appearance.sizes.iconLarge
                        color: ifaceCard.isConnected
                            ? Common.Appearance.m3colors.primary
                            : Common.Appearance.m3colors.onSurfaceVariant
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: ifaceCard.isWifi && ifaceCard.isConnected && modelData.ssid
                                ? modelData.ssid
                                : modelData.device
                            font.family: Common.Appearance.fonts.main
                            font.pixelSize: Common.Appearance.fontSize.normal
                            font.weight: Font.Medium
                            color: Common.Appearance.m3colors.onSurface
                        }

                        Text {
                            text: {
                                if (ifaceCard.isConnected) {
                                    return ifaceCard.isWifi ? "Connected" : "Connected"
                                }
                                return modelData.state === "unavailable" ? "Cable unplugged" : "Disconnected"
                            }
                            font.family: Common.Appearance.fonts.main
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: ifaceCard.isConnected
                                ? Common.Appearance.m3colors.primary
                                : Common.Appearance.m3colors.onSurfaceVariant
                        }
                    }

                    // WiFi toggle (only for wifi interfaces)
                    MouseArea {
                        visible: ifaceCard.isWifi
                        Layout.preferredWidth: 52
                        Layout.preferredHeight: 32
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.Network.setWifiEnabled(!Services.Network.wifiEnabled)

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: Services.Network.wifiEnabled
                                ? Common.Appearance.m3colors.primary
                                : Common.Appearance.m3colors.surfaceVariant
                            border.width: Services.Network.wifiEnabled ? 0 : 2
                            border.color: Common.Appearance.m3colors.outline

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Rectangle {
                                width: Services.Network.wifiEnabled ? 24 : 16
                                height: Services.Network.wifiEnabled ? 24 : 16
                                radius: height / 2
                                anchors.verticalCenter: parent.verticalCenter
                                x: Services.Network.wifiEnabled ? parent.width - width - 4 : 4
                                color: Services.Network.wifiEnabled
                                    ? Common.Appearance.m3colors.onPrimary
                                    : Common.Appearance.m3colors.outline

                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
                                Behavior on width { NumberAnimation { duration: 150 } }
                                Behavior on height { NumberAnimation { duration: 150 } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                    }
                }

                // Connection details (when connected)
                ColumnLayout {
                    visible: ifaceCard.isConnected
                    Layout.fillWidth: true
                    spacing: Common.Appearance.spacing.tiny

                    // IP Address
                    RowLayout {
                        visible: modelData.ipAddress
                        Layout.fillWidth: true
                        Text {
                            text: "IP Address"
                            font.family: Common.Appearance.fonts.main
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.m3colors.onSurfaceVariant
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: modelData.ipAddress || "—"
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.m3colors.onSurface
                        }
                    }

                    // Gateway
                    RowLayout {
                        visible: modelData.gateway
                        Layout.fillWidth: true
                        Text {
                            text: "Gateway"
                            font.family: Common.Appearance.fonts.main
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.m3colors.onSurfaceVariant
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: modelData.gateway || "—"
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.m3colors.onSurface
                        }
                    }

                    // MAC Address
                    RowLayout {
                        visible: modelData.macAddress
                        Layout.fillWidth: true
                        Text {
                            text: "MAC"
                            font.family: Common.Appearance.fonts.main
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.m3colors.onSurfaceVariant
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: modelData.macAddress || "—"
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.m3colors.onSurface
                        }
                    }

                    // Signal strength (WiFi only)
                    RowLayout {
                        visible: ifaceCard.isWifi && modelData.strength > 0
                        Layout.fillWidth: true
                        Text {
                            text: "Signal"
                            font.family: Common.Appearance.fonts.main
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.m3colors.onSurfaceVariant
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: modelData.strength + "%"
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.m3colors.onSurface
                        }
                    }

                    // Security (WiFi only)
                    RowLayout {
                        visible: ifaceCard.isWifi && modelData.security
                        Layout.fillWidth: true
                        Text {
                            text: "Security"
                            font.family: Common.Appearance.fonts.main
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.m3colors.onSurfaceVariant
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: modelData.security || "Open"
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.m3colors.onSurface
                        }
                    }
                }

                // Disconnected ethernet info
                ColumnLayout {
                    visible: ifaceCard.isEthernet && !ifaceCard.isConnected && modelData.macAddress
                    Layout.fillWidth: true
                    spacing: Common.Appearance.spacing.tiny

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "MAC"
                            font.family: Common.Appearance.fonts.main
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.m3colors.onSurfaceVariant
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: modelData.macAddress
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.m3colors.onSurface
                        }
                    }
                }
            }
            }
        }
    }

    // ===== Available WiFi Networks Section =====
    ColumnLayout {
        visible: Services.Network.wifiAvailable && Services.Network.wifiEnabled
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        // Section header with scan button
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Available Networks"
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
                onClicked: Services.Network.startScan()

                Rectangle {
                    anchors.fill: parent
                    radius: Common.Appearance.rounding.small
                    color: parent.containsMouse ? Common.Appearance.m3colors.surfaceVariant : "transparent"
                }

                Common.Icon {
                    id: scanIcon
                    anchors.centerIn: parent
                    name: Common.Icons.icons.refresh
                    size: Common.Appearance.sizes.iconSmall
                    color: Services.Network.scanning
                        ? Common.Appearance.m3colors.primary
                        : Common.Appearance.m3colors.onSurfaceVariant

                    RotationAnimation on rotation {
                        running: Services.Network.scanning
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
            visible: Services.Network.scanning && Services.Network.availableNetworks.length === 0
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            radius: Common.Appearance.rounding.large
            color: Common.Appearance.m3colors.surfaceVariant

            Text {
                anchors.centerIn: parent
                text: "Scanning for networks..."
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.normal
                color: Common.Appearance.m3colors.onSurfaceVariant
            }
        }

        // Available networks list
        Rectangle {
            visible: Services.Network.availableNetworks.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: networksColumn.implicitHeight + Common.Appearance.spacing.medium * 2
            radius: Common.Appearance.rounding.large
            color: Common.Appearance.m3colors.surfaceVariant

            ColumnLayout {
                id: networksColumn
                anchors.fill: parent
                anchors.margins: Common.Appearance.spacing.medium
                spacing: Common.Appearance.spacing.small

                Repeater {
                    model: ScriptModel {
                        values: Services.Network.availableNetworks
                    }

                    delegate: NetworkItem {
                        Layout.fillWidth: true
                        ssid: modelData.ssid
                        strength: modelData.strength
                        security: modelData.security
                        saved: modelData.saved
                        isConnected: Services.Network.ssid === modelData.ssid && Services.Network.connected
                        onConnectClicked: {
                            if (modelData.saved || !modelData.security) {
                                Services.Network.connectToNetwork(modelData.ssid)
                            } else {
                                console.log("Need password for", modelData.ssid)
                            }
                        }
                        onForgetClicked: Services.Network.forgetNetwork(modelData.ssid)
                    }
                }
            }
        }

        // Idle state - prompt to scan
        Rectangle {
            visible: !Services.Network.scanning && Services.Network.availableNetworks.length === 0
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

    // ===== Network Item Component =====
    component NetworkItem: MouseArea {
        id: netItem
        property string ssid: ""
        property int strength: 0
        property string security: ""
        property bool saved: false
        property bool isConnected: false

        signal connectClicked()
        signal forgetClicked()

        implicitHeight: 48
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: if (!isConnected) connectClicked()

        Rectangle {
            anchors.fill: parent
            radius: Common.Appearance.rounding.medium
            color: netItem.isConnected
                ? Common.Appearance.m3colors.primaryContainer
                : (netItem.containsMouse ? Common.Appearance.surfaceLayer(2) : "transparent")
        }

        RowLayout {
            anchors.fill: parent
            spacing: Common.Appearance.spacing.medium

            Common.Icon {
                name: Common.Icons.icons.wifi
                size: Common.Appearance.sizes.iconMedium
                color: netItem.isConnected
                    ? Common.Appearance.m3colors.onPrimaryContainer
                    : (netItem.strength >= 50
                        ? Common.Appearance.m3colors.onSurface
                        : Common.Appearance.m3colors.onSurfaceVariant)
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: netItem.ssid
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.normal
                    color: netItem.isConnected
                        ? Common.Appearance.m3colors.onPrimaryContainer
                        : Common.Appearance.m3colors.onSurface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: Common.Appearance.spacing.small

                    Text {
                        text: netItem.isConnected ? "Connected" : (netItem.saved ? "Saved" : netItem.strength + "%")
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: netItem.isConnected
                            ? Common.Appearance.m3colors.onPrimaryContainer
                            : Common.Appearance.m3colors.onSurfaceVariant
                    }

                    Text {
                        visible: netItem.security && netItem.security !== "--"
                        text: "•"
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.m3colors.onSurfaceVariant
                    }

                    Common.Icon {
                        visible: netItem.security && netItem.security !== "--"
                        name: Common.Icons.icons.lock
                        size: 12
                        color: netItem.isConnected
                            ? Common.Appearance.m3colors.onPrimaryContainer
                            : Common.Appearance.m3colors.onSurfaceVariant
                    }
                }
            }

            MouseArea {
                visible: netItem.containsMouse && netItem.saved && !netItem.isConnected
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    mouse.accepted = true
                    netItem.forgetClicked()
                }

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
