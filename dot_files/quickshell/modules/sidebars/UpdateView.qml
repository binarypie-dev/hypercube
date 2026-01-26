import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

import "../common" as Common
import "../../" as Root
import "../../services" as Services

// System updates view for the left sidebar
ColumnLayout {
    id: root
    spacing: Common.Appearance.spacing.large

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        Text {
            Layout.fillWidth: true
            text: "System Updates"
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

            onClicked: Root.GlobalStates.sidebarLeftOpen = false

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

    // System Updates Card
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: updatesContent.implicitHeight + Common.Appearance.spacing.medium * 2
        radius: Common.Appearance.rounding.large
        color: Common.Appearance.m3colors.surfaceVariant

        ColumnLayout {
            id: updatesContent
            anchors.fill: parent
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.medium

                Common.Icon {
                    name: Services.Updates.updateCount > 0
                        ? Common.Icons.icons.update
                        : Common.Icons.icons.checkCircle
                    size: Common.Appearance.sizes.iconLarge
                    color: Services.Updates.updateCount > 0
                        ? Common.Appearance.m3colors.primary
                        : Common.Appearance.m3colors.onSurfaceVariant
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "System Updates"
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.normal
                        font.weight: Font.Medium
                        color: Common.Appearance.m3colors.onSurface
                    }

                    Text {
                        text: Services.Updates.summary()
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.m3colors.onSurfaceVariant
                    }
                }

                // Refresh button
                MouseArea {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    enabled: !Services.Updates.checking

                    onClicked: Services.Updates.checkUpdates()

                    Rectangle {
                        anchors.fill: parent
                        radius: Common.Appearance.rounding.small
                        color: parent.containsMouse ? Common.Appearance.m3colors.surface : "transparent"
                    }

                    Common.Icon {
                        anchors.centerIn: parent
                        name: Common.Icons.icons.refresh
                        size: Common.Appearance.sizes.iconSmall
                        color: Common.Appearance.m3colors.onSurfaceVariant
                        opacity: Services.Updates.checking ? 0.5 : 1

                        RotationAnimation on rotation {
                            running: Services.Updates.checking
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                        }
                    }
                }
            }

            // Last checked
            Text {
                visible: Services.Updates.lastChecked !== ""
                text: "Last checked: " + Services.Updates.lastChecked
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.smallest
                color: Common.Appearance.m3colors.onSurfaceVariant
                opacity: 0.7
            }
        }
    }

    // Spacer
    Item { Layout.fillHeight: true }
}
