import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../common" as Common
import "../../services" as Services

// Vim-style app switcher overlay with TUI aesthetics
PanelWindow {
    id: root

    required property var targetScreen
    screen: targetScreen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    visible: Services.Windows.switcherActive

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "appswitcher"

    FocusScope {
        id: focusRoot
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Tab) {
                if (event.modifiers & Qt.ShiftModifier) {
                    Services.Windows.prevWindow()
                } else {
                    Services.Windows.nextWindow()
                }
                event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
                Services.Windows.cancelSwitcher()
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                Services.Windows.selectWindow()
                event.accepted = true
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                Services.Windows.prevWindow()
                event.accepted = true
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                Services.Windows.nextWindow()
                event.accepted = true
            } else if (event.key === Qt.Key_J) {
                Services.Windows.nextWindow()
                event.accepted = true
            } else if (event.key === Qt.Key_K) {
                Services.Windows.prevWindow()
                event.accepted = true
            }
        }

        Keys.onReleased: (event) => {
            if (event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R || event.key === Qt.Key_Meta) {
                Services.Windows.selectWindow()
                event.accepted = true
            }
        }

        // Dark overlay
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.6)

            MouseArea {
                anchors.fill: parent
                onClicked: Services.Windows.cancelSwitcher()
            }
        }
    }

    // Switcher panel (TUI style - like a floating vim window)
    Rectangle {
        id: switcherPanel
        anchors.centerIn: parent

        readonly property int itemWidth: 100
        readonly property int itemSpacing: 2
        readonly property int windowCount: Services.Windows.windows.length
        readonly property int contentWidth: windowCount > 0
            ? (windowCount * itemWidth) + ((windowCount - 1) * itemSpacing)
            : 200

        width: Math.min(parent.width * 0.85, contentWidth + Common.Appearance.spacing.medium * 2 + 4)
        height: 140
        radius: Common.Appearance.rounding.tiny
        color: Qt.rgba(
            Common.Appearance.colors.bgDark.r,
            Common.Appearance.colors.bgDark.g,
            Common.Appearance.colors.bgDark.b,
            0.96
        )
        border.width: Common.Appearance.borderWidth.thin
        border.color: Common.Appearance.colors.border

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Title bar (vim-style)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 22
                color: Common.Appearance.colors.bgHighlight

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Common.Appearance.colors.border
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Common.Appearance.spacing.small
                    anchors.rightMargin: Common.Appearance.spacing.small

                    Text {
                        text: "[ Switch Window ]"
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.tiny
                        font.bold: true
                        color: Common.Appearance.colors.fg
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "[" + (Services.Windows.currentIndex + 1) + "/" + Services.Windows.windows.length + "]"
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.tiny
                        color: Common.Appearance.colors.comment
                    }
                }
            }

            // Window list
            ListView {
                id: switcherRow
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: Common.Appearance.spacing.small
                orientation: ListView.Horizontal
                spacing: switcherPanel.itemSpacing
                clip: true

                model: Services.Windows.windows
                currentIndex: Services.Windows.currentIndex

                highlightFollowsCurrentItem: true
                highlightMoveDuration: Common.Appearance.animation.fast

                delegate: Item {
                    id: windowDelegate
                    required property var modelData
                    required property int index

                    width: switcherPanel.itemWidth
                    height: switcherRow.height

                    // Selection highlight (vim visual style)
                    Rectangle {
                        anchors.fill: parent
                        radius: Common.Appearance.rounding.tiny
                        color: switcherRow.currentIndex === windowDelegate.index
                            ? Common.Appearance.colors.bgVisual
                            : (delegateMouse.containsMouse
                                ? Common.Appearance.colors.bgHighlight
                                : "transparent")
                        border.width: switcherRow.currentIndex === windowDelegate.index ? 1 : 0
                        border.color: Common.Appearance.colors.blue
                    }

                    MouseArea {
                        id: delegateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            Services.Windows.currentIndex = windowDelegate.index
                            Services.Windows.selectWindow()
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Common.Appearance.spacing.tiny
                        spacing: Common.Appearance.spacing.tiny

                        // App icon
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            Layout.alignment: Qt.AlignHCenter

                            property string cachedIcon: modelData.class ? Services.IconResolver.getIcon(modelData.class) : ""

                            Image {
                                id: appIcon
                                anchors.centerIn: parent
                                width: 36
                                height: 36
                                source: parent.cachedIcon
                                sourceSize: Qt.size(36, 36)
                                smooth: true
                                visible: status === Image.Ready
                            }

                            // Fallback: colored letter (TUI style)
                            Rectangle {
                                anchors.centerIn: parent
                                width: 36
                                height: 36
                                visible: appIcon.status !== Image.Ready
                                radius: Common.Appearance.rounding.tiny
                                color: Common.Appearance.colors.bgVisual
                                border.width: 1
                                border.color: Common.Appearance.colors.border

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.class ? modelData.class.charAt(0).toUpperCase() : "?"
                                    font.family: Common.Appearance.fonts.mono
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: Common.Appearance.colors.cyan
                                }
                            }
                        }

                        // Window title
                        Text {
                            Layout.fillWidth: true
                            text: modelData.class || "Window"
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.tiny
                            color: switcherRow.currentIndex === windowDelegate.index
                                ? Common.Appearance.colors.fg
                                : Common.Appearance.colors.fgDark
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        // Workspace indicator
                        Text {
                            Layout.fillWidth: true
                            text: "ws:" + (modelData.workspace ? modelData.workspace.id : "?")
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.tiny - 2
                            color: Common.Appearance.colors.comment
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            // Keyboard hints bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                color: Common.Appearance.colors.bgDark

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Common.Appearance.colors.border
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Common.Appearance.spacing.small
                    anchors.rightMargin: Common.Appearance.spacing.small
                    spacing: Common.Appearance.spacing.large

                    Repeater {
                        model: [
                            { key: "Tab/h/l", action: "navigate" },
                            { key: "Enter", action: "select" },
                            { key: "Esc", action: "cancel" }
                        ]

                        Row {
                            spacing: Common.Appearance.spacing.tiny

                            Rectangle {
                                width: keyText.implicitWidth + Common.Appearance.spacing.small * 2
                                height: 14
                                radius: Common.Appearance.rounding.tiny
                                color: Common.Appearance.colors.bgVisual
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    id: keyText
                                    anchors.centerIn: parent
                                    text: modelData.key
                                    font.family: Common.Appearance.fonts.mono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Common.Appearance.colors.cyan
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.action
                                font.family: Common.Appearance.fonts.mono
                                font.pixelSize: 9
                                color: Common.Appearance.colors.fgDark
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }
    }

    // Current window title (vim-style message line)
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: switcherPanel.bottom
        anchors.topMargin: Common.Appearance.spacing.small
        width: titleText.implicitWidth + Common.Appearance.spacing.large * 2
        height: 22
        radius: Common.Appearance.rounding.tiny
        color: Qt.rgba(
            Common.Appearance.colors.bgDark.r,
            Common.Appearance.colors.bgDark.g,
            Common.Appearance.colors.bgDark.b,
            0.96
        )
        border.width: Common.Appearance.borderWidth.thin
        border.color: Common.Appearance.colors.border
        visible: Services.Windows.windows.length > 0

        Text {
            id: titleText
            anchors.centerIn: parent
            text: {
                const windows = Services.Windows.windows
                const idx = Services.Windows.currentIndex
                if (windows.length > 0 && idx < windows.length) {
                    return "\"" + (windows[idx].title || windows[idx].class || "") + "\""
                }
                return ""
            }
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.tiny
            color: Common.Appearance.colors.fgDark
            maximumLineCount: 1
            elide: Text.ElideMiddle
        }
    }

    onVisibleChanged: {
        if (visible) {
            focusRoot.forceActiveFocus()
        }
    }
}
