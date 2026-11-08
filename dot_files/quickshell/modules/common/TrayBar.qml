import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

import "." as Common
import "../../services" as Services

// Row of system tray icons. Left click activates, middle click is the
// secondary action, right click (or menu-only items) opens the item's menu,
// scroll is forwarded to the item.
RowLayout {
    id: root
    spacing: 0

    readonly property bool hasItems: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayItem
            required property var modelData

            Layout.preferredHeight: 26
            Layout.preferredWidth: 26

            property string iconSource: {
                const icon = modelData.icon
                if (!icon || icon.includes("?path=")) return ""
                if (icon.startsWith("/")) return "file://" + icon
                if (icon.startsWith("file://") || icon.startsWith("image://")) return icon
                return "image://icon/" + icon
            }
            property bool primaryFailed: trayIcon.status !== Image.Ready
            property string fallbackSource: primaryFailed
                ? Services.IconResolver.getIcon(modelData.title) : ""

            Image {
                id: trayIcon
                anchors.centerIn: parent
                width: Common.Appearance.sizes.iconSmall
                height: Common.Appearance.sizes.iconSmall
                sourceSize: Qt.size(width, height)
                source: trayItem.iconSource
                smooth: true
                visible: status === Image.Ready
            }

            Image {
                id: trayFallback
                anchors.centerIn: parent
                width: Common.Appearance.sizes.iconSmall
                height: Common.Appearance.sizes.iconSmall
                sourceSize: Qt.size(width, height)
                source: trayItem.fallbackSource
                smooth: true
                visible: trayItem.primaryFailed && status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: trayItem.primaryFailed && trayFallback.status !== Image.Ready
                text: trayItem.modelData.title ? trayItem.modelData.title.charAt(0).toUpperCase() : "?"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: 10
                font.bold: true
                color: Common.Appearance.colors.fg
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                onClicked: (mouse) => {
                    const item = trayItem.modelData
                    if (mouse.button === Qt.RightButton || (item.onlyMenu && item.hasMenu)) {
                        if (item.hasMenu) {
                            const pos = trayItem.mapToItem(null, 0, trayItem.height)
                            item.display(trayItem.QsWindow.window, pos.x, pos.y)
                        }
                    } else if (mouse.button === Qt.MiddleButton) {
                        item.secondaryActivate()
                    } else {
                        item.activate()
                    }
                }

                onWheel: (wheel) => trayItem.modelData.scroll(wheel.angleDelta.y, false)

                Rectangle {
                    anchors.fill: parent
                    radius: Common.Appearance.rounding.tiny
                    color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                }
            }
        }
    }
}
