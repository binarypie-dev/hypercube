import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

import "../common" as Common
import "../../" as Root
import "../../services" as Services

// System updates view for the left sidebar - TUI style
ColumnLayout {
    id: root
    spacing: Common.Appearance.spacing.medium
    anchors.topMargin: 5
    anchors.bottomMargin: 5

    // Header
    Text {
        Layout.fillWidth: true
        text: "System Updates"
        font.family: Common.Appearance.fonts.mono
        font.pixelSize: Common.Appearance.fontSize.large
        font.bold: true
        color: Common.Appearance.colors.fg
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
                    name: Services.Updates.updateCount > 0
                        ? Common.Icons.icons.download
                        : Common.Icons.icons.checkCircle
                    size: 20
                    color: Services.Updates.updateCount > 0
                        ? Common.Appearance.colors.cyan
                        : Common.Appearance.colors.green
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: Services.Updates.updateCount > 0
                            ? "[" + Services.Updates.updateCount + " updates available]"
                            : "[System up to date]"
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.normal
                        font.bold: true
                        color: Services.Updates.updateCount > 0
                            ? Common.Appearance.colors.cyan
                            : Common.Appearance.colors.fg
                    }

                    Text {
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

    // Spacer
    Item { Layout.fillHeight: true }
}
