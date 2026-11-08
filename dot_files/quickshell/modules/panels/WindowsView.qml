import QtQuick
import QtQuick.Layouts

import "../common" as Common
import "../../services" as Services

// Open windows (the alt-tab switcher, as a hub tab) with the system tray
// above them. Mod+Tab opens the hub
// straight here; each further Mod+Tab / Mod+Shift+Tab steps the selection
// and releasing Super focuses the selected window.
FocusScope {
    id: root
    focus: true

    readonly property int rowHeight: 40

    // Opening the tab by hand (Ctrl+9 / click) starts a switcher session so
    // selection and Enter work the same as with Mod+Tab
    Component.onCompleted: {
        if (!Services.Windows.switcherActive && !Services.Windows.switcherPending) {
            Services.Windows.startSwitcher(0)
        }
    }

    Keys.onPressed: (event) => {
        switch (event.key) {
            case Qt.Key_Down:
            case Qt.Key_J:
                Services.Windows.nextWindow()
                break
            case Qt.Key_Up:
            case Qt.Key_K:
                Services.Windows.prevWindow()
                break
            case Qt.Key_Return:
            case Qt.Key_Enter:
                Services.Windows.selectWindow()
                break
            default:
                return
        }
        event.accepted = true
    }

    // Releasing Super commits the selection (Mod+Tab hold-and-release)
    Keys.onReleased: (event) => {
        if (event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R || event.key === Qt.Key_Meta) {
            Services.Windows.selectWindow()
            event.accepted = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Common.Appearance.spacing.medium

        // System tray
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: trayRow.implicitHeight + Common.Appearance.spacing.small * 2
            visible: trayBar.hasItems
            color: Common.Appearance.colors.bgDark
            border.width: 1
            border.color: Common.Appearance.colors.border
            radius: Common.Appearance.rounding.tiny

            RowLayout {
                id: trayRow
                anchors.fill: parent
                anchors.leftMargin: Common.Appearance.spacing.medium
                anchors.rightMargin: Common.Appearance.spacing.small
                spacing: Common.Appearance.spacing.medium

                Text {
                    text: "Tray"
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.small
                    font.bold: true
                    color: Common.Appearance.colors.fgDark
                }

                Item { Layout.fillWidth: true }

                Common.TrayBar {
                    id: trayBar
                }
            }
        }

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "Windows"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.large
                font.bold: true
                color: Common.Appearance.colors.fg
            }

            Text {
                text: Services.Windows.windows.length > 0
                    ? (Services.Windows.currentIndex + 1) + "/" + Services.Windows.windows.length
                    : "0/0"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.colors.comment
            }
        }

        ListView {
            id: windowList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            model: Services.Windows.windows
            currentIndex: Services.Windows.currentIndex
            highlightFollowsCurrentItem: true
            highlightMoveDuration: Common.Appearance.animation.fast
            highlightRangeMode: ListView.ApplyRange
            preferredHighlightBegin: root.rowHeight
            preferredHighlightEnd: height - root.rowHeight

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool selected: windowList.currentIndex === index

                width: windowList.width
                height: root.rowHeight

                Rectangle {
                    anchors.fill: parent
                    radius: Common.Appearance.rounding.tiny
                    color: row.selected
                        ? Common.Appearance.colors.bgVisual
                        : (rowMouse.containsMouse
                            ? Common.Appearance.colors.bgHighlight
                            : "transparent")
                }

                // Selection marker (vim-style gutter)
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    width: 3
                    radius: 1
                    color: Common.Appearance.colors.modeVisual
                    visible: row.selected
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        Services.Windows.currentIndex = row.index
                        Services.Windows.selectWindow()
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Common.Appearance.spacing.medium + 2
                    anchors.rightMargin: Common.Appearance.spacing.medium
                    spacing: Common.Appearance.spacing.medium

                    // App icon (letter fallback)
                    Item {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24

                        property string cachedIcon: row.modelData.class
                            ? Services.IconResolver.getIcon(row.modelData.class) : ""

                        Image {
                            id: appIcon
                            anchors.fill: parent
                            source: parent.cachedIcon
                            sourceSize: Qt.size(24, 24)
                            smooth: true
                            visible: status === Image.Ready
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: appIcon.status !== Image.Ready
                            radius: Common.Appearance.rounding.tiny
                            color: Common.Appearance.colors.bgHighlight
                            border.width: 1
                            border.color: Common.Appearance.colors.border

                            Text {
                                anchors.centerIn: parent
                                text: row.modelData.class ? row.modelData.class.charAt(0).toUpperCase() : "?"
                                font.family: Common.Appearance.fonts.mono
                                font.pixelSize: 12
                                font.bold: true
                                color: Common.Appearance.colors.cyan
                            }
                        }
                    }

                    // App name
                    Text {
                        Layout.preferredWidth: 130
                        text: row.modelData.class || "window"
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.small
                        font.bold: row.selected
                        color: row.selected ? Common.Appearance.colors.fg : Common.Appearance.colors.blue
                        elide: Text.ElideRight
                    }

                    // Window title
                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.title || ""
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: row.selected ? Common.Appearance.colors.fg : Common.Appearance.colors.fgDark
                        elide: Text.ElideRight
                    }

                    // Workspace
                    Text {
                        // Hyprland 0.57+ omits workspace.id for special workspaces; fall back to the name
                        text: "ws" + (row.modelData.workspace
                            ? (row.modelData.workspace.id ?? row.modelData.workspace.name)
                            : "?")
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.colors.comment
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: windowList.count === 0
                text: "-- no windows --"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.colors.comment
            }
        }
    }
}
