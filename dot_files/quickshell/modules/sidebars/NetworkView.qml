import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import "../common" as Common
import "../../services" as Services
import "../../" as Root

// Network settings view - TUI style
ColumnLayout {
    id: root
    spacing: Common.Appearance.spacing.medium
    anchors.topMargin: 5
    anchors.bottomMargin: 5

    property string selectedSsid: ""
    property string selectedSecurity: ""
    property bool showPasswordDialog: false

    function showPasswordPrompt(ssid, security) {
        selectedSsid = ssid
        selectedSecurity = security
        showPasswordDialog = true
        passwordField.text = ""
        passwordField.focusInput()
    }

    function hidePasswordPrompt() {
        showPasswordDialog = false
        selectedSsid = ""
        selectedSecurity = ""
        passwordField.text = ""
    }

    function connectWithPassword() {
        if (passwordField.text.length > 0) {
            Services.Network.connectToNetwork(selectedSsid, passwordField.text)
            hidePasswordPrompt()
        }
    }

    Component.onCompleted: {
        Services.Network.refresh()
        Services.Network.loadSavedNetworks()
    }

    Component.onDestruction: {
        Services.Network.availableNetworks = []
    }

    // Header
    Text {
        Layout.fillWidth: true
        text: "Network"
        font.family: Common.Appearance.fonts.mono
        font.pixelSize: Common.Appearance.fontSize.large
        font.bold: true
        color: Common.Appearance.colors.fg
    }

    // Password Dialog
    Rectangle {
        visible: root.showPasswordDialog
        Layout.fillWidth: true
        Layout.preferredHeight: pwdContent.height + Common.Appearance.spacing.medium * 2
        color: Common.Appearance.colors.bgDark
        border.width: 1
        border.color: Common.Appearance.colors.cyan
        radius: Common.Appearance.rounding.tiny

        ColumnLayout {
            id: pwdContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            Text {
                text: root.selectedSsid
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.normal
                font.bold: true
                color: Common.Appearance.colors.fg
            }

            Text {
                text: "Enter password to connect"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.colors.fgDark
            }

            Common.TuiInput {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: "Password"
                password: !showPasswordToggle.checked
                onAccepted: root.connectWithPassword()
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.small

                Common.TuiToggle {
                    id: showPasswordToggle
                    checked: false
                }

                Text {
                    text: "Show"
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Common.Appearance.colors.fgDark
                }

                Item { Layout.fillWidth: true }

                Common.TuiButton {
                    text: "Cancel"
                    onClicked: root.hidePasswordPrompt()
                }

                Common.TuiButton {
                    text: "Connect"
                    primary: true
                    enabled: passwordField.text.length > 0
                    onClicked: root.connectWithPassword()
                }
            }
        }
    }

    // Interface List
    Repeater {
        id: interfaceRepeater
        model: ScriptModel {
            values: Services.Network.interfaces
        }

        delegate: Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: ifaceContent.height + Common.Appearance.spacing.medium * 2

            required property var modelData
            required property int index

            property bool isConnected: modelData.state === "connected"
            property bool isWifi: modelData.type === "wifi"
            property bool isEthernet: modelData.type === "ethernet"

            color: Common.Appearance.colors.bgDark
            border.width: 1
            border.color: Common.Appearance.colors.border
            radius: Common.Appearance.rounding.tiny

            ColumnLayout {
                id: ifaceContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Common.Appearance.spacing.medium
                spacing: Common.Appearance.spacing.small

                // Header row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Common.Appearance.spacing.medium

                    Common.Icon {
                        name: isWifi
                            ? (isConnected ? Common.Icons.icons.wifi : Common.Icons.icons.wifiOff)
                            : Common.Icons.icons.ethernet
                        size: 20
                        color: isConnected ? Common.Appearance.colors.fg : Common.Appearance.colors.fgDark
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: isWifi && isConnected && modelData.ssid
                                ? modelData.ssid
                                : modelData.device
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.normal
                            font.bold: true
                            color: Common.Appearance.colors.fg
                        }

                        Text {
                            text: {
                                if (isConnected) return "[Connected]"
                                if (modelData.state === "unavailable") return "[Cable unplugged]"
                                return "[Disconnected]"
                            }
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: isConnected
                                ? Common.Appearance.colors.green
                                : Common.Appearance.colors.fgDark
                        }
                    }

                    Common.TuiToggle {
                        visible: isWifi
                        checked: Services.Network.wifiEnabled
                        onToggled: Services.Network.setWifiEnabled(!Services.Network.wifiEnabled)
                    }
                }

                // Connection details
                ColumnLayout {
                    visible: isConnected
                    Layout.fillWidth: true
                    spacing: 2

                    NetworkDetail { label: "IP"; value: modelData.ipAddress || "—" }
                    NetworkDetail { label: "Gateway"; value: modelData.gateway || "—"; visible: !!modelData.gateway }
                    NetworkDetail { label: "MAC"; value: modelData.macAddress || "—" }
                    NetworkDetail { label: "Signal"; value: "[" + modelData.strength + "%]"; visible: isWifi && modelData.strength > 0 }
                    NetworkDetail { label: "Security"; value: modelData.security || "Open"; visible: isWifi && !!modelData.security }
                }

                // Disconnected ethernet info
                ColumnLayout {
                    visible: isEthernet && !isConnected && !!modelData.macAddress
                    Layout.fillWidth: true
                    spacing: 2

                    NetworkDetail { label: "MAC"; value: modelData.macAddress }
                }
            }
        }
    }

    // Available WiFi Networks Section
    ColumnLayout {
        visible: Services.Network.wifiAvailable && Services.Network.wifiEnabled
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "Available Networks"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                font.bold: true
                color: Common.Appearance.colors.fgDark
            }

            Common.TuiButton {
                icon: Common.Icons.icons.refresh
                onClicked: Services.Network.startScan()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: networksContent.height + Common.Appearance.spacing.small * 2
            color: Common.Appearance.colors.bgDark
            border.width: 1
            border.color: Common.Appearance.colors.border
            radius: Common.Appearance.rounding.tiny

            ColumnLayout {
                id: networksContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Common.Appearance.spacing.small
                spacing: 0

                // Scanning state
                Text {
                    visible: Services.Network.scanning && Services.Network.availableNetworks.length === 0
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
                    visible: !Services.Network.scanning && Services.Network.availableNetworks.length === 0
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
                            if (modelData.saved || !modelData.security || modelData.security === "--") {
                                Services.Network.connectToNetwork(modelData.ssid)
                            } else {
                                root.showPasswordPrompt(modelData.ssid, modelData.security)
                            }
                        }
                        onForgetClicked: Services.Network.forgetNetwork(modelData.ssid)
                    }
                }
            }
        }
    }

    // Spacer
    Item { Layout.fillHeight: true }

    // Network Detail Component
    component NetworkDetail: RowLayout {
        property string label: ""
        property string value: ""

        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.medium

        Text {
            text: label
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.small
            color: Common.Appearance.colors.fgDark
        }

        Item { Layout.fillWidth: true }

        Text {
            text: value
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.small
            color: Common.Appearance.colors.fg
        }
    }

    // Network Item Component
    component NetworkItem: Rectangle {
        id: netItem
        property string ssid: ""
        property int strength: 0
        property string security: ""
        property bool saved: false
        property bool isConnected: false

        signal connectClicked()
        signal forgetClicked()

        Layout.fillWidth: true
        height: 32
        color: netMouse.containsMouse
            ? Common.Appearance.colors.bgHighlight
            : (isConnected ? Common.Appearance.colors.bgVisual : "transparent")

        MouseArea {
            id: netMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: isConnected ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: if (!isConnected) connectClicked()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Common.Appearance.spacing.medium
            anchors.rightMargin: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.small

            Text {
                Layout.fillWidth: true
                text: ssid
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.normal
                color: Common.Appearance.colors.fg
                elide: Text.ElideRight
            }

            Common.Icon {
                visible: security && security !== "--"
                name: Common.Icons.icons.lock
                size: 12
                color: Common.Appearance.colors.fgDark
            }

            Text {
                text: {
                    if (isConnected) return "[Connected]"
                    if (saved) return "[Saved]"
                    return "[" + strength + "%]"
                }
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                font.bold: isConnected
                color: isConnected ? Common.Appearance.colors.green : Common.Appearance.colors.fgDark
            }

            Common.TuiButton {
                visible: saved && !isConnected
                icon: Common.Icons.icons.remove
                danger: true
                onClicked: netItem.forgetClicked()
            }
        }
    }
}
