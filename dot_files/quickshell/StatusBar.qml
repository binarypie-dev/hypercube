import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray

Rectangle {
    id: statusBar
    width: parent.width
    height: 40
    radius: 8
    color: "#24283b"

    // Required properties from parent
    required property string activeView
    required property int notificationCount
    required property string currentDate
    required property string currentTime
    required property string weatherTemp
    required property string weatherIcon

    // Signals to communicate with parent
    signal toggleNotifications()
    signal toggleCalendar()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        // Notification icon
        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 6
            color: notifMouseArea.containsMouse ? "#33467c" : (statusBar.activeView === "notifications" ? "#33467c" : "transparent")

            Text {
                anchors.centerIn: parent
                text: "󰂚"
                font.family: "JetBrains Mono"
                font.pixelSize: 16
                color: statusBar.notificationCount > 0 ? "#ff9e64" : "#7aa2f7"
            }

            MouseArea {
                id: notifMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: statusBar.toggleNotifications()
            }
        }

        // Separator
        Text {
            text: "|"
            font.family: "JetBrains Mono"
            font.pixelSize: 14
            color: "#33467c"
        }

        // System Tray
        Row {
            spacing: 4

            Repeater {
                model: SystemTray.items

                delegate: Rectangle {
                    id: trayItemRect
                    width: 24
                    height: 24
                    radius: 4
                    color: trayMouseArea.containsMouse ? "#33467c" : "transparent"

                    Image {
                        id: trayIcon
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: modelData.icon ?? ""
                        sourceSize: Qt.size(18, 18)
                        cache: false
                        visible: status === Image.Ready
                    }

                    // Fallback when icon can't load
                    Text {
                        anchors.centerIn: parent
                        text: modelData.title ? modelData.title.charAt(0).toUpperCase() : "?"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        font.bold: true
                        color: "#c0caf5"
                        visible: trayIcon.status !== Image.Ready
                    }

                    QsMenuAnchor {
                        id: trayMenuAnchor
                        menu: modelData.menu
                        anchor.item: trayItemRect
                        anchor.edges: Edges.Bottom
                        anchor.gravity: Edges.Bottom
                    }

                    MouseArea {
                        id: trayMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton || modelData.onlyMenu) {
                                if (modelData.hasMenu) {
                                    trayMenuAnchor.open();
                                }
                            } else if (mouse.button === Qt.MiddleButton) {
                                modelData.secondaryActivate();
                            } else {
                                modelData.activate();
                            }
                        }
                        onWheel: (wheel) => {
                            modelData.scroll(wheel.angleDelta.y / 120, false);
                        }
                    }

                    ToolTip.visible: trayMouseArea.containsMouse && modelData.tooltipTitle
                    ToolTip.text: modelData.tooltipTitle || modelData.title
                    ToolTip.delay: 500
                }
            }
        }

        // Separator
        Text {
            text: "|"
            font.family: "JetBrains Mono"
            font.pixelSize: 14
            color: "#33467c"
        }

        // Date/Time clickable area
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 6
            color: dateTimeMouseArea.containsMouse ? "#33467c" : "transparent"

            MouseArea {
                id: dateTimeMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: statusBar.toggleCalendar()
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 12

                // Date
                Text {
                    text: statusBar.currentDate
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    color: "#c0caf5"
                }

                Item { Layout.fillWidth: true }

                // Weather
                Row {
                    spacing: 6
                    visible: statusBar.weatherTemp !== ""

                    Text {
                        text: statusBar.weatherIcon
                        font.family: "JetBrains Mono"
                        font.pixelSize: 14
                        color: "#7aa2f7"
                    }

                    Text {
                        text: statusBar.weatherTemp
                        font.family: "JetBrains Mono"
                        font.pixelSize: 14
                        color: "#c0caf5"
                    }
                }

                // Separator
                Text {
                    text: "|"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    color: "#33467c"
                    visible: statusBar.weatherTemp !== ""
                }

                // Time
                Text {
                    text: statusBar.currentTime
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    color: "#c0caf5"
                }
            }
        }
    }
}
