import QtQuick
import QtQuick.Layouts

Rectangle {
    id: helpView
    width: parent.width
    height: visible ? helpContent.implicitHeight : 0
    color: "transparent"
    clip: true

    required property bool isVisible
    visible: isVisible

    Behavior on height {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
    }

    Column {
        id: helpContent
        width: parent.width
        spacing: 8

        // Commands section
        Rectangle {
            width: parent.width
            height: commandsCol.implicitHeight + 16
            radius: 6
            color: "#24283b"

            Column {
                id: commandsCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                spacing: 6

                Text {
                    text: "Commands"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                    font.bold: true
                    color: "#7aa2f7"
                }

                // Command list
                Repeater {
                    model: [
                        { cmd: "/? or /help", desc: "Show this help" },
                        { cmd: "/c or /calendar", desc: "Show calendar" },
                        { cmd: "/n or /notifications", desc: "Show notifications" },
                        { cmd: "/b or /bluetooth", desc: "Bluetooth controls" }
                    ]

                    Row {
                        spacing: 12
                        Text {
                            width: 140
                            text: modelData.cmd
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                            color: "#9ece6a"
                        }
                        Text {
                            text: modelData.desc
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                            color: "#c0caf5"
                        }
                    }
                }
            }
        }

        // Keyboard shortcuts section
        Rectangle {
            width: parent.width
            height: shortcutsCol.implicitHeight + 16
            radius: 6
            color: "#24283b"

            Column {
                id: shortcutsCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                spacing: 6

                Text {
                    text: "Keyboard Shortcuts"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                    font.bold: true
                    color: "#7aa2f7"
                }

                Repeater {
                    model: [
                        { key: "Ctrl+C", desc: "Open calendar" },
                        { key: "Ctrl+N", desc: "Open notifications" },
                        { key: "Ctrl+B", desc: "Open bluetooth" },
                        { key: "Ctrl+J", desc: "Focus list (in notifications)" },
                        { key: "Ctrl+K", desc: "Return to input" },
                        { key: "Escape", desc: "Clear input / close HUD" },
                        { key: "↑ / ↓", desc: "Navigate list" },
                        { key: "j / k", desc: "Navigate list (vim)" },
                        { key: "Enter", desc: "Launch app / confirm" },
                        { key: "d / x", desc: "Dismiss notification" }
                    ]

                    Row {
                        spacing: 12
                        Text {
                            width: 140
                            text: modelData.key
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                            color: "#ff9e64"
                        }
                        Text {
                            text: modelData.desc
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                            color: "#c0caf5"
                        }
                    }
                }
            }
        }

        // Tips section
        Rectangle {
            width: parent.width
            height: tipsCol.implicitHeight + 16
            radius: 6
            color: "#24283b"

            Column {
                id: tipsCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                spacing: 6

                Text {
                    text: "Tips"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                    font.bold: true
                    color: "#7aa2f7"
                }

                Text {
                    width: parent.width
                    text: "• Type to search applications\n• Click date/time to toggle calendar\n• Click bell icon to toggle notifications"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    color: "#c0caf5"
                    lineHeight: 1.4
                }
            }
        }
    }
}
