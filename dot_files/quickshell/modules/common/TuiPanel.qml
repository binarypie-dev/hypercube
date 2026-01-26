import QtQuick
import QtQuick.Layouts

// Vim-style floating panel with TUI borders and title bar
Rectangle {
    id: root

    // Panel title (displayed in title bar, vim-style)
    property string title: ""

    // Keyboard hints shown at bottom
    property var keyHints: []  // Array of {key: "Esc", action: "close"}

    // Content item
    default property alias content: contentContainer.data

    // Colors
    color: Qt.rgba(
        Appearance.colors.bg.r,
        Appearance.colors.bg.g,
        Appearance.colors.bg.b,
        Appearance.panelOpacity
    )

    // TUI-style border
    border.width: Appearance.borderWidth.thin
    border.color: Appearance.colors.border

    // Match Hyprland window rounding
    radius: Appearance.rounding.window

    // Layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Title bar (vim-style)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.title !== "" ? 24 : 0
            visible: root.title !== ""
            color: Appearance.colors.bgHighlight

            // Bottom border
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Appearance.colors.border
            }

            // Title text (centered, vim-style)
            Text {
                anchors.centerIn: parent
                text: root.title
                font.family: Appearance.fonts.mono
                font.pixelSize: Appearance.fontSize.small
                font.bold: true
                color: Appearance.colors.fg
            }
        }

        // Content area
        Item {
            id: contentContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Appearance.spacing.medium
        }

        // Keyboard hints bar (like which-key)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.keyHints.length > 0 ? 22 : 0
            visible: root.keyHints.length > 0
            color: Appearance.colors.bgDark

            // Top border
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: Appearance.colors.border
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.spacing.medium
                anchors.rightMargin: Appearance.spacing.medium
                spacing: Appearance.spacing.large

                Repeater {
                    model: root.keyHints

                    Row {
                        spacing: Appearance.spacing.tiny

                        // Key badge
                        Rectangle {
                            width: keyText.implicitWidth + Appearance.spacing.small * 2
                            height: 16
                            radius: Appearance.rounding.tiny
                            color: Appearance.colors.bgVisual
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                id: keyText
                                anchors.centerIn: parent
                                text: modelData.key
                                font.family: Appearance.fonts.mono
                                font.pixelSize: Appearance.fontSize.tiny
                                font.bold: true
                                color: Appearance.colors.cyan
                            }
                        }

                        // Action text
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.action
                            font.family: Appearance.fonts.mono
                            font.pixelSize: Appearance.fontSize.tiny
                            color: Appearance.colors.fgDark
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }
}
