import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

Scope {
    id: notificationsRoot

    property var notificationList: []
    property int maxNotifications: 5

    function addNotification(notification) {
        // Add to front of list
        notificationList = [notification].concat(notificationList).slice(0, maxNotifications);

        // Auto-dismiss after timeout (default 5 seconds)
        var timeout = notification.expireTimeout > 0 ? notification.expireTimeout : 5000;
        Qt.callLater(() => {
            dismissTimer.notification = notification;
            dismissTimer.interval = timeout;
            dismissTimer.start();
        });
    }

    function dismissNotification(notification) {
        notification.dismiss();
        notificationList = notificationList.filter(n => n !== notification);
    }

    Timer {
        id: dismissTimer
        property var notification: null
        onTriggered: {
            if (notification) {
                notificationsRoot.dismissNotification(notification);
            }
        }
    }

    // Notification popup window
    PanelWindow {
        id: notificationWindow

        visible: notificationsRoot.notificationList.length > 0

        anchors {
            top: true
            right: true
        }

        margins {
            top: 10
            right: 10
        }

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay

        implicitWidth: 380
        implicitHeight: notificationColumn.implicitHeight + 20
        color: "transparent"

        // Don't block input
        mask: Region {}

        ColumnLayout {
            id: notificationColumn
            anchors {
                fill: parent
                margins: 10
            }
            spacing: 8

            Repeater {
                model: notificationsRoot.notificationList

                delegate: Rectangle {
                    id: notificationItem
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.preferredHeight: contentColumn.implicitHeight + 24
                    radius: 10
                    color: "#1a1b26"
                    border.color: "#33467c"
                    border.width: 1

                    // Hover effect
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "#7aa2f7"
                        opacity: closeMouseArea.containsMouse ? 0.1 : 0
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            margins: 12
                        }
                        spacing: 12

                        // App icon
                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: 8
                            color: "#33467c"

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 20
                                color: "#7aa2f7"
                            }

                            Image {
                                anchors.centerIn: parent
                                width: 32
                                height: 32
                                source: modelData.appIcon ? "image://icon/" + modelData.appIcon : ""
                                visible: status === Image.Ready
                            }
                        }

                        // Content
                        ColumnLayout {
                            id: contentColumn
                            Layout.fillWidth: true
                            spacing: 4

                            // App name / summary row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.summary || modelData.appName || "Notification"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: "#c0caf5"
                                    elide: Text.ElideRight
                                }

                                // Close button
                                Rectangle {
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    radius: 10
                                    color: closeMouseArea.containsMouse ? "#f7768e" : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: ""
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        color: closeMouseArea.containsMouse ? "#1a1b26" : "#565f89"
                                    }

                                    MouseArea {
                                        id: closeMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: notificationsRoot.dismissNotification(modelData)
                                    }
                                }
                            }

                            // Body text
                            Text {
                                Layout.fillWidth: true
                                text: modelData.body || ""
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                color: "#565f89"
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                visible: text !== ""
                            }

                            // Action buttons
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: modelData.actions && modelData.actions.length > 0

                                Repeater {
                                    model: modelData.actions || []

                                    delegate: Rectangle {
                                        required property var modelData

                                        Layout.preferredHeight: 24
                                        Layout.preferredWidth: actionText.implicitWidth + 16
                                        radius: 4
                                        color: actionMouse.containsMouse ? "#7aa2f7" : "#33467c"

                                        Text {
                                            id: actionText
                                            anchors.centerIn: parent
                                            text: modelData.text || "Action"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 11
                                            color: actionMouse.containsMouse ? "#1a1b26" : "#c0caf5"
                                        }

                                        MouseArea {
                                            id: actionMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                modelData.invoke();
                                                notificationsRoot.dismissNotification(notificationItem.modelData);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Click to dismiss
                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: notificationsRoot.dismissNotification(modelData)
                    }
                }
            }
        }
    }
}
