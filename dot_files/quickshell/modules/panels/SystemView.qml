import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import "../common" as Common
import "../../services" as Services
import "../../" as Root

// System view - image updates, battery, power profile and session actions
Flickable {
    id: root
    contentHeight: contentColumn.height
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        width: 6

        contentItem: Rectangle {
            implicitWidth: 4
            radius: 2
            color: Common.Appearance.colors.bgVisual
        }
    }

    ColumnLayout {
        id: contentColumn
        width: root.width
        spacing: Common.Appearance.spacing.medium

        // Header
        Text {
            Layout.fillWidth: true
            text: "System"
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.large
            font.bold: true
            color: Common.Appearance.colors.fg
        }

        // Updates
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Common.Appearance.spacing.small

            Text {
                text: "Updates"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                font.bold: true
                color: Common.Appearance.colors.fgDark
            }

            // System Updates Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: updateContent.height + Common.Appearance.spacing.medium * 2
                color: Common.Appearance.colors.bgDark
                border.width: 1
                border.color: Common.Appearance.colors.border
                radius: Common.Appearance.rounding.tiny

                ColumnLayout {
                    id: updateContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Common.Appearance.spacing.medium
                    spacing: Common.Appearance.spacing.medium

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Common.Appearance.spacing.medium

                        // Status icon
                        Common.Icon {
                            name: Services.Updates.error !== ""
                                ? Common.Icons.icons.warning
                                : (Services.Updates.needsAttention
                                    ? Common.Icons.icons.download
                                    : Common.Icons.icons.checkCircle)
                            size: 20
                            color: Services.Updates.error !== ""
                                ? Common.Appearance.colors.yellow
                                : (Services.Updates.needsAttention
                                    ? Common.Appearance.colors.cyan
                                    : Common.Appearance.colors.green)
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: Services.Updates.checking ? "[Checking]"
                                    : Services.Updates.error !== "" ? "[Check failed]"
                                    : Services.Updates.updateCount > 0 ? "[Update available]"
                                    : Services.Updates.rebootRequired ? "[Reboot required]"
                                    : "[System up to date]"
                                font.family: Common.Appearance.fonts.mono
                                font.pixelSize: Common.Appearance.fontSize.normal
                                font.bold: true
                                color: Services.Updates.needsAttention
                                    ? Common.Appearance.colors.cyan
                                    : Common.Appearance.colors.fg
                            }

                            Text {
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                text: Services.Updates.summary()
                                font.family: Common.Appearance.fonts.mono
                                font.pixelSize: Common.Appearance.fontSize.small
                                color: Common.Appearance.colors.fgDark
                            }
                        }

                        // Refresh button
                        Common.TuiButton {
                            icon: Common.Icons.icons.refresh
                            enabled: !Services.Updates.checking
                            onClicked: Services.Updates.checkUpdates()
                        }
                    }

                    // Image being tracked
                    Text {
                        Layout.fillWidth: true
                        visible: Services.Updates.imageRef !== ""
                        text: "Image: " + Services.Updates.imageRef
                        elide: Text.ElideMiddle
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.colors.comment
                    }

                    // Last checked
                    Text {
                        visible: Services.Updates.lastChecked !== ""
                        text: "Last checked: " + Services.Updates.lastChecked
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.colors.comment
                    }
                }
            }
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
    }
}
