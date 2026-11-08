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

    // Spacer
    Item { Layout.fillHeight: true }
}
