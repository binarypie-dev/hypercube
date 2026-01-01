import QtQuick
import QtQuick.Layouts
import Quickshell

import "../common" as Common
import "../../services" as Services
import "../../" as Root

// Power settings view for the right sidebar
ColumnLayout {
    id: root
    spacing: Common.Appearance.spacing.large

    // Refresh power profiles when view opens
    Component.onCompleted: {
        // Power service auto-refreshes
    }

    // Header with close button
    RowLayout {
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        Text {
            Layout.fillWidth: true
            text: "Power"
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

    // ===== SECTION 1: Battery Status (if present) =====
    Rectangle {
        visible: Services.Battery.present
        Layout.fillWidth: true
        Layout.preferredHeight: batteryContent.implicitHeight + Common.Appearance.spacing.medium * 2
        radius: Common.Appearance.rounding.large
        color: Common.Appearance.m3colors.surfaceVariant

        ColumnLayout {
            id: batteryContent
            anchors.fill: parent
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            // Battery header row
            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.medium

                Common.Icon {
                    name: {
                        if (Services.Battery.pluggedIn && Services.Battery.percent >= 95) {
                            return Common.Icons.icons.plug
                        } else if (Services.Battery.charging) {
                            return Common.Icons.icons.batteryCharging
                        } else {
                            return Common.Icons.batteryIcon(Services.Battery.percent, false)
                        }
                    }
                    size: Common.Appearance.sizes.iconXLarge
                    color: {
                        if (Services.Battery.percent <= 20 && !Services.Battery.charging) {
                            return Common.Appearance.m3colors.error
                        } else if (Services.Battery.charging || Services.Battery.pluggedIn) {
                            return Common.Appearance.m3colors.primary
                        }
                        return Common.Appearance.m3colors.onSurface
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: Services.Battery.percent + "%"
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.title
                        font.weight: Font.Medium
                        color: Common.Appearance.m3colors.onSurface
                    }

                    Text {
                        text: {
                            if (Services.Battery.pluggedIn && Services.Battery.percent >= 95) {
                                return "Fully charged"
                            } else if (Services.Battery.charging) {
                                const timeStr = Services.Battery.timeRemainingString()
                                return "Charging" + (timeStr ? " - " + timeStr + " until full" : "")
                            } else {
                                const timeStr = Services.Battery.timeRemainingString()
                                return timeStr ? timeStr + " remaining" : "On battery"
                            }
                        }
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.m3colors.onSurfaceVariant
                    }
                }
            }

            // Battery progress bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 8
                radius: 4
                color: Common.Appearance.m3colors.surface

                Rectangle {
                    width: parent.width * (Services.Battery.percent / 100)
                    height: parent.height
                    radius: parent.radius
                    color: {
                        if (Services.Battery.percent <= 10) {
                            return Common.Appearance.m3colors.error
                        } else if (Services.Battery.percent <= 20) {
                            return Common.Appearance.m3colors.orange
                        } else if (Services.Battery.charging || Services.Battery.pluggedIn) {
                            return Common.Appearance.m3colors.primary
                        }
                        return Common.Appearance.m3colors.tertiary
                    }

                    Behavior on width {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }

    // ===== SECTION 2: Power Profile (if available and battery present) =====
    ColumnLayout {
        visible: Services.Power.profilesAvailable && Services.Battery.present
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        Text {
            text: "Power Profile"
            font.family: Common.Appearance.fonts.main
            font.pixelSize: Common.Appearance.fontSize.small
            font.weight: Font.Medium
            color: Common.Appearance.m3colors.onSurfaceVariant
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: profilesColumn.implicitHeight + Common.Appearance.spacing.medium * 2
            radius: Common.Appearance.rounding.large
            color: Common.Appearance.m3colors.surfaceVariant

            ColumnLayout {
                id: profilesColumn
                anchors.fill: parent
                anchors.margins: Common.Appearance.spacing.medium
                spacing: Common.Appearance.spacing.small

                Repeater {
                    model: Services.Power.availableProfiles

                    delegate: MouseArea {
                        id: profileItem
                        required property string modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: Services.Power.setProfile(modelData)

                        Rectangle {
                            anchors.fill: parent
                            radius: Common.Appearance.rounding.medium
                            color: profileItem.modelData === Services.Power.currentProfile
                                ? Common.Appearance.m3colors.primaryContainer
                                : (profileItem.containsMouse
                                    ? Common.Appearance.surfaceLayer(2)
                                    : "transparent")

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Common.Appearance.spacing.medium
                            anchors.rightMargin: Common.Appearance.spacing.medium
                            spacing: Common.Appearance.spacing.medium

                            Common.Icon {
                                name: Services.Power.profileIcon(profileItem.modelData)
                                size: Common.Appearance.sizes.iconMedium
                                color: profileItem.modelData === Services.Power.currentProfile
                                    ? Common.Appearance.m3colors.onPrimaryContainer
                                    : Common.Appearance.m3colors.onSurfaceVariant
                            }

                            Text {
                                Layout.fillWidth: true
                                text: Services.Power.profileDisplayName(profileItem.modelData)
                                font.family: Common.Appearance.fonts.main
                                font.pixelSize: Common.Appearance.fontSize.normal
                                color: profileItem.modelData === Services.Power.currentProfile
                                    ? Common.Appearance.m3colors.onPrimaryContainer
                                    : Common.Appearance.m3colors.onSurface
                            }

                            Common.Icon {
                                visible: profileItem.modelData === Services.Power.currentProfile
                                name: Common.Icons.icons.check
                                size: Common.Appearance.sizes.iconSmall
                                color: Common.Appearance.m3colors.onPrimaryContainer
                            }
                        }
                    }
                }
            }
        }
    }

    // ===== SECTION 3: Session Actions =====
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        Text {
            text: "Session"
            font.family: Common.Appearance.fonts.main
            font.pixelSize: Common.Appearance.fontSize.small
            font.weight: Font.Medium
            color: Common.Appearance.m3colors.onSurfaceVariant
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: actionsGrid.implicitHeight + Common.Appearance.spacing.medium * 2
            radius: Common.Appearance.rounding.large
            color: Common.Appearance.m3colors.surfaceVariant

            GridLayout {
                id: actionsGrid
                anchors.fill: parent
                anchors.margins: Common.Appearance.spacing.medium
                columns: 2
                rowSpacing: Common.Appearance.spacing.small
                columnSpacing: Common.Appearance.spacing.small

                // Lock
                PowerActionButton {
                    Layout.fillWidth: true
                    icon: Common.Icons.icons.lock
                    label: "Lock"
                    onClicked: {
                        Root.GlobalStates.closeAll()
                        Services.Power.lock()
                    }
                }

                // Suspend
                PowerActionButton {
                    Layout.fillWidth: true
                    icon: Common.Icons.icons.sleep
                    label: "Suspend"
                    onClicked: {
                        Root.GlobalStates.closeAll()
                        Services.Power.suspend()
                    }
                }

                // Logout
                PowerActionButton {
                    Layout.fillWidth: true
                    icon: Common.Icons.icons.logout
                    label: "Log Out"
                    onClicked: {
                        Root.GlobalStates.closeAll()
                        Services.Power.logout()
                    }
                }

                // Restart
                PowerActionButton {
                    Layout.fillWidth: true
                    icon: Common.Icons.icons.restart
                    label: "Restart"
                    dangerous: true
                    onClicked: {
                        Root.GlobalStates.closeAll()
                        Services.Power.reboot()
                    }
                }

                // Power Off (spans 2 columns)
                PowerActionButton {
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    icon: Common.Icons.icons.power
                    label: "Power Off"
                    dangerous: true
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

    // ===== Power Action Button Component =====
    component PowerActionButton: MouseArea {
        id: actionButton
        property string icon: ""
        property string label: ""
        property bool dangerous: false

        implicitHeight: 56
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: Common.Appearance.rounding.medium
            color: actionButton.containsMouse
                ? (actionButton.dangerous
                    ? Common.Appearance.m3colors.errorContainer
                    : Common.Appearance.surfaceLayer(2))
                : "transparent"

            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Common.Appearance.spacing.tiny

            Common.Icon {
                Layout.alignment: Qt.AlignHCenter
                name: actionButton.icon
                size: Common.Appearance.sizes.iconMedium
                color: actionButton.dangerous && actionButton.containsMouse
                    ? Common.Appearance.m3colors.onErrorContainer
                    : Common.Appearance.m3colors.onSurface
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: actionButton.label
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.small
                color: actionButton.dangerous && actionButton.containsMouse
                    ? Common.Appearance.m3colors.onErrorContainer
                    : Common.Appearance.m3colors.onSurface
            }
        }
    }
}
