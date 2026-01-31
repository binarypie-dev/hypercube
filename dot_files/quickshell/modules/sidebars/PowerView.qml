import QtQuick
import QtQuick.Layouts
import Quickshell

import "../common" as Common
import "../../services" as Services
import "../../" as Root

// Power settings view - TUI style
ColumnLayout {
    id: root
    spacing: Common.Appearance.spacing.medium
    anchors.topMargin: 5
    anchors.bottomMargin: 5

    // Header
    Text {
        Layout.fillWidth: true
        text: "Power"
        font.family: Common.Appearance.fonts.mono
        font.pixelSize: Common.Appearance.fontSize.large
        font.bold: true
        color: Common.Appearance.colors.fg
    }

    // Battery Status
    Rectangle {
        visible: Services.Battery.present
        Layout.fillWidth: true
        Layout.preferredHeight: batteryContent.height + Common.Appearance.spacing.medium * 2
        color: Common.Appearance.colors.bgDark
        border.width: 1
        border.color: Common.Appearance.colors.border
        radius: Common.Appearance.rounding.tiny

        ColumnLayout {
            id: batteryContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            Text {
                text: "Battery"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                font.bold: true
                color: Common.Appearance.colors.fgDark
            }

            // Battery header row
            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.medium

                Common.Icon {
                    name: Common.Icons.batteryIcon(Services.Battery.percent, Services.Battery.charging)
                    size: 24
                    color: {
                        if (Services.Battery.percent <= 20 && !Services.Battery.charging) {
                            return Common.Appearance.colors.red
                        }
                        if (Services.Battery.charging || Services.Battery.pluggedIn) {
                            return Common.Appearance.colors.cyan
                        }
                        return Common.Appearance.colors.fg
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "[" + Services.Battery.percent + "%]"
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.large
                        font.bold: true
                        color: {
                            if (Services.Battery.percent <= 20 && !Services.Battery.charging) {
                                return Common.Appearance.colors.red
                            }
                            if (Services.Battery.charging || Services.Battery.pluggedIn) {
                                return Common.Appearance.colors.cyan
                            }
                            return Common.Appearance.colors.fg
                        }
                    }

                    Text {
                        text: {
                            if (Services.Battery.pluggedIn && Services.Battery.percent >= 95) {
                                return "Fully charged"
                            } else if (Services.Battery.charging) {
                                const timeStr = Services.Battery.timeRemainingString()
                                return "Charging" + (timeStr ? " - " + timeStr : "")
                            } else {
                                const timeStr = Services.Battery.timeRemainingString()
                                return timeStr ? timeStr + " remaining" : "On battery"
                            }
                        }
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.colors.fgDark
                    }
                }
            }

            // Battery progress bar
            Common.TuiProgress {
                Layout.fillWidth: true
                value: Services.Battery.percent / 100
                useThresholds: true
                lowThreshold: 20
                mediumThreshold: 50
                normalColor: Services.Battery.charging
                    ? Common.Appearance.colors.cyan
                    : Common.Appearance.colors.green
            }
        }
    }

    // Power Profile
    ColumnLayout {
        visible: Services.Power.profilesAvailable && Services.Battery.present
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        Text {
            text: "Power Profile"
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.small
            font.bold: true
            color: Common.Appearance.colors.fgDark
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: profilesContent.height + Common.Appearance.spacing.small * 2
            color: Common.Appearance.colors.bgDark
            border.width: 1
            border.color: Common.Appearance.colors.border
            radius: Common.Appearance.rounding.tiny

            ColumnLayout {
                id: profilesContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Common.Appearance.spacing.small
                spacing: 0

                Repeater {
                    model: Services.Power.availableProfiles

                    delegate: Rectangle {
                        id: profileItem
                        required property string modelData

                        Layout.fillWidth: true
                        height: 32
                        color: profileMouse.containsMouse
                            ? Common.Appearance.colors.bgHighlight
                            : (modelData === Services.Power.currentProfile ? Common.Appearance.colors.bgVisual : "transparent")

                        MouseArea {
                            id: profileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.Power.setProfile(modelData)
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Common.Appearance.spacing.medium
                            anchors.rightMargin: Common.Appearance.spacing.medium
                            spacing: Common.Appearance.spacing.small

                            Text {
                                Layout.fillWidth: true
                                text: Services.Power.profileDisplayName(modelData)
                                font.family: Common.Appearance.fonts.mono
                                font.pixelSize: Common.Appearance.fontSize.normal
                                color: Common.Appearance.colors.fg
                            }

                            Text {
                                visible: modelData === Services.Power.currentProfile
                                text: "[*]"
                                font.family: Common.Appearance.fonts.mono
                                font.pixelSize: Common.Appearance.fontSize.small
                                font.bold: true
                                color: Common.Appearance.colors.cyan
                            }
                        }
                    }
                }
            }
        }
    }

    // Session Actions
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        Text {
            text: "Session"
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.small
            font.bold: true
            color: Common.Appearance.colors.fgDark
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: actionsGrid.height + Common.Appearance.spacing.medium * 2
            color: Common.Appearance.colors.bgDark
            border.width: 1
            border.color: Common.Appearance.colors.border
            radius: Common.Appearance.rounding.tiny

            GridLayout {
                id: actionsGrid
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Common.Appearance.spacing.medium
                columns: 2
                rowSpacing: Common.Appearance.spacing.small
                columnSpacing: Common.Appearance.spacing.small

                Common.TuiButton {
                    Layout.fillWidth: true
                    icon: Common.Icons.icons.lock
                    text: "Lock"
                    onClicked: {
                        Root.GlobalStates.closeAll()
                        Services.Power.lock()
                    }
                }

                Common.TuiButton {
                    Layout.fillWidth: true
                    icon: Common.Icons.icons.sleep
                    text: "Suspend"
                    onClicked: {
                        Root.GlobalStates.closeAll()
                        Services.Power.suspend()
                    }
                }

                Common.TuiButton {
                    Layout.fillWidth: true
                    icon: Common.Icons.icons.logout
                    text: "Log Out"
                    onClicked: {
                        Root.GlobalStates.closeAll()
                        Services.Power.logout()
                    }
                }

                Common.TuiButton {
                    Layout.fillWidth: true
                    icon: Common.Icons.icons.restart
                    text: "Restart"
                    danger: true
                    onClicked: {
                        Root.GlobalStates.closeAll()
                        Services.Power.reboot()
                    }
                }

                Common.TuiButton {
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    icon: Common.Icons.icons.power
                    text: "Power Off"
                    danger: true
                    onClicked: {
                        Root.GlobalStates.closeAll()
                        Services.Power.powerOff()
                    }
                }
            }
        }
    }

    // Spacer
    Item { Layout.fillHeight: true }
}
