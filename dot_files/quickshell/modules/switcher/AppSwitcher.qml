import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../common" as Common
import "../../services" as Services

// App switcher overlay - centered on screen
PanelWindow {
    id: root

    required property var targetScreen
    screen: targetScreen

    // Center on screen
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

    // Focus scope for keyboard handling
    FocusScope {
        id: focusRoot
        anchors.fill: parent
        focus: true

        // Keyboard handling
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
            } else if (event.key === Qt.Key_Left) {
                Services.Windows.prevWindow()
                event.accepted = true
            } else if (event.key === Qt.Key_Right) {
                Services.Windows.nextWindow()
                event.accepted = true
            }
        }

        Keys.onReleased: (event) => {
            // When Super (Meta) is released, select the current window
            if (event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R || event.key === Qt.Key_Meta) {
                Services.Windows.selectWindow()
                event.accepted = true
            }
        }

        // Dark overlay background
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.5)

            MouseArea {
                anchors.fill: parent
                onClicked: Services.Windows.cancelSwitcher()
            }
        }
    }

    // Switcher panel - centered
    Rectangle {
        id: switcherPanel
        anchors.centerIn: parent

        // Calculate width based on number of windows
        readonly property int itemWidth: 120
        readonly property int itemSpacing: Common.Appearance.spacing.medium
        readonly property int windowCount: Services.Windows.windows.length
        readonly property int contentWidth: windowCount > 0
            ? (windowCount * itemWidth) + ((windowCount - 1) * itemSpacing)
            : 200  // Minimum width when no windows

        width: Math.min(parent.width * 0.8, contentWidth + Common.Appearance.spacing.large * 2)
        height: 160
        radius: Common.Appearance.rounding.large
        color: Qt.rgba(
            Common.Appearance.m3colors.surface.r,
            Common.Appearance.m3colors.surface.g,
            Common.Appearance.m3colors.surface.b,
            0.95
        )

        // Window list
        ListView {
            id: switcherRow
            anchors.fill: parent
            anchors.margins: Common.Appearance.spacing.medium
            orientation: ListView.Horizontal
            spacing: switcherPanel.itemSpacing
            clip: true

            model: Services.Windows.windows
            currentIndex: Services.Windows.currentIndex

            highlightFollowsCurrentItem: true
            highlightMoveDuration: 150

            delegate: Item {
                id: windowDelegate
                required property var modelData
                required property int index

                width: switcherPanel.itemWidth
                height: switcherRow.height

                Rectangle {
                    anchors.fill: parent
                    radius: Common.Appearance.rounding.medium
                    color: switcherRow.currentIndex === windowDelegate.index
                        ? Common.Appearance.m3colors.primaryContainer
                        : (delegateMouse.containsMouse
                            ? Common.Appearance.m3colors.surfaceVariant
                            : "transparent")

                    Behavior on color {
                        ColorAnimation { duration: 100 }
                    }
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
                    anchors.margins: Common.Appearance.spacing.small
                    spacing: Common.Appearance.spacing.tiny

                    // App icon
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        Layout.alignment: Qt.AlignHCenter

                        // Get icon from IconResolver service
                        property string cachedIcon: modelData.class ? Services.IconResolver.getIcon(modelData.class) : ""

                        // Primary: datacube cached icon
                        Image {
                            id: appIcon
                            anchors.centerIn: parent
                            width: 48
                            height: 48
                            source: parent.cachedIcon
                            sourceSize: Qt.size(48, 48)
                            smooth: true
                            visible: status === Image.Ready
                        }

                        // Fallback letter icon
                        Rectangle {
                            anchors.centerIn: parent
                            width: 48
                            height: 48
                            visible: appIcon.status !== Image.Ready
                            radius: Common.Appearance.rounding.medium
                            color: Common.Appearance.m3colors.secondaryContainer

                            Text {
                                anchors.centerIn: parent
                                text: modelData.class ? modelData.class.charAt(0).toUpperCase() : "?"
                                font.pixelSize: 20
                                font.bold: true
                                color: Common.Appearance.m3colors.onSecondaryContainer
                            }
                        }
                    }

                    // Window title
                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: modelData.title || modelData.class || "Window"
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: switcherRow.currentIndex === windowDelegate.index
                            ? Common.Appearance.m3colors.onPrimaryContainer
                            : Common.Appearance.m3colors.onSurface
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }

                    // Workspace indicator
                    Text {
                        Layout.fillWidth: true
                        text: "Workspace " + (modelData.workspace ? modelData.workspace.id : "?")
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.small - 2
                        color: Common.Appearance.m3colors.onSurfaceVariant
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

    // Current window title at bottom
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: switcherPanel.bottom
        anchors.topMargin: Common.Appearance.spacing.medium
        width: titleText.implicitWidth + Common.Appearance.spacing.large * 2
        height: titleText.implicitHeight + Common.Appearance.spacing.medium
        radius: Common.Appearance.rounding.medium
        color: Qt.rgba(
            Common.Appearance.m3colors.surface.r,
            Common.Appearance.m3colors.surface.g,
            Common.Appearance.m3colors.surface.b,
            0.95
        )
        visible: Services.Windows.windows.length > 0

        Text {
            id: titleText
            anchors.centerIn: parent
            text: {
                const windows = Services.Windows.windows
                const idx = Services.Windows.currentIndex
                if (windows.length > 0 && idx < windows.length) {
                    return windows[idx].title || windows[idx].class || ""
                }
                return ""
            }
            font.family: Common.Appearance.fonts.main
            font.pixelSize: Common.Appearance.fontSize.normal
            color: Common.Appearance.m3colors.onSurface
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
