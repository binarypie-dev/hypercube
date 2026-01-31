import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

import "../common" as Common
import "../../services" as Services
import "../../" as Root

// Notifications view - TUI style
ColumnLayout {
    id: root
    spacing: Common.Appearance.spacing.medium
    anchors.topMargin: 5
    anchors.bottomMargin: 5

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        Text {
            Layout.fillWidth: true
            text: "Notifications"
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.large
            font.bold: true
            color: Common.Appearance.colors.fg
        }

        Common.TuiButton {
            visible: Services.Notifications.notifications.length > 0
            icon: Common.Icons.icons.delete
            text: "Clear"
            onClicked: {
                Services.Notifications.clearAll()
                Root.GlobalStates.unreadNotificationCount = 0
            }
        }
    }

    // Do Not Disturb toggle
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: dndContent.height + Common.Appearance.spacing.medium * 2
        color: Common.Appearance.colors.bgDark
        border.width: 1
        border.color: Common.Appearance.colors.border
        radius: Common.Appearance.rounding.tiny

        RowLayout {
            id: dndContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            Common.Icon {
                name: Root.GlobalStates.doNotDisturb
                    ? Common.Icons.icons.doNotDisturb
                    : Common.Icons.icons.notification
                size: 20
                color: Root.GlobalStates.doNotDisturb
                    ? Common.Appearance.colors.cyan
                    : Common.Appearance.colors.fg
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: "Do Not Disturb"
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.normal
                    font.bold: true
                    color: Common.Appearance.colors.fg
                }

                Text {
                    text: Root.GlobalStates.doNotDisturb ? "[Enabled]" : "[Disabled]"
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Root.GlobalStates.doNotDisturb
                        ? Common.Appearance.colors.cyan
                        : Common.Appearance.colors.fgDark
                }
            }

            Common.TuiToggle {
                checked: Root.GlobalStates.doNotDisturb
                onToggled: Root.GlobalStates.doNotDisturb = !Root.GlobalStates.doNotDisturb
            }
        }
    }

    // Notifications list
    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: notificationsColumn.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 6

            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: Common.Appearance.colors.bgVisual
            }
        }

        ColumnLayout {
            id: notificationsColumn
            width: parent.width
            spacing: Common.Appearance.spacing.small

            // Empty state
            Rectangle {
                visible: Services.Notifications.notifications.length === 0
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: Common.Appearance.colors.bgDark
                border.width: 1
                border.color: Common.Appearance.colors.border
                radius: Common.Appearance.rounding.tiny

                Text {
                    anchors.centerIn: parent
                    text: "-- No notifications --"
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Common.Appearance.colors.comment
                }
            }

            // Notification list
            Repeater {
                model: Services.Notifications.notifications

                delegate: NotificationItem {
                    Layout.fillWidth: true
                    notification: modelData
                    onDismissed: {
                        Services.Notifications.removeNotification(modelData.id)
                        if (Root.GlobalStates.unreadNotificationCount > 0) {
                            Root.GlobalStates.unreadNotificationCount--
                        }
                    }
                    onActionClicked: function(actionId) {
                        Services.Notifications.invokeAction(modelData.id, actionId)
                        if (Root.GlobalStates.unreadNotificationCount > 0) {
                            Root.GlobalStates.unreadNotificationCount--
                        }
                    }
                }
            }
        }
    }

    // Notification item component
    component NotificationItem: Rectangle {
        id: notifItem
        property var notification: ({})
        signal dismissed()
        signal actionClicked(string actionId)

        property bool hasSingleAction: notification.actions && notification.actions.length === 1

        Layout.fillWidth: true
        height: notifContent.height + Common.Appearance.spacing.medium * 2

        color: notifMouse.containsMouse
            ? Common.Appearance.colors.bgHighlight
            : Common.Appearance.colors.bgDark
        border.width: 1
        border.color: Common.Appearance.colors.border
        radius: Common.Appearance.rounding.tiny

        MouseArea {
            id: notifMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: hasSingleAction ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (hasSingleAction) {
                    notifItem.actionClicked(notification.actions[0].identifier || "")
                }
            }
        }

        RowLayout {
            id: notifContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.small

            // App icon
            Item {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignTop

                property string resolvedIcon: notification.appName ? Services.IconResolver.getIcon(notification.appName) : ""
                property string fallbackIcon: notification.appIcon || ""
                property string iconSource: resolvedIcon || (fallbackIcon ? "image://icon/" + fallbackIcon : "")

                Image {
                    id: notifIcon
                    anchors.fill: parent
                    source: parent.iconSource
                    sourceSize: Qt.size(28, 28)
                    smooth: true
                    visible: status === Image.Ready
                }

                Rectangle {
                    anchors.fill: parent
                    visible: notifIcon.status !== Image.Ready
                    radius: Common.Appearance.rounding.tiny
                    color: Common.Appearance.colors.bgVisual

                    Text {
                        anchors.centerIn: parent
                        text: notification.appName ? notification.appName.charAt(0).toUpperCase() : "?"
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: 12
                        font.bold: true
                        color: Common.Appearance.colors.cyan
                    }
                }
            }

            // Content
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                // Header row
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: notification.summary || notification.appName || "Notification"
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.normal
                        font.bold: true
                        color: Common.Appearance.colors.fg
                        elide: Text.ElideRight
                    }

                    Text {
                        text: formatTime(notification.time)
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.colors.comment
                    }
                }

                // Body
                Text {
                    visible: notification.body && notification.body !== ""
                    Layout.fillWidth: true
                    text: notification.body
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Common.Appearance.colors.fgDark
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }

                // Actions
                RowLayout {
                    visible: notification.actions && notification.actions.length > 1
                    Layout.fillWidth: true
                    spacing: Common.Appearance.spacing.small

                    Repeater {
                        model: notification.actions || []

                        Common.TuiButton {
                            required property var modelData
                            text: modelData.text || "Action"
                            onClicked: notifItem.actionClicked(modelData.identifier || "")
                        }
                    }
                }
            }

            // Dismiss button
            Common.TuiButton {
                visible: notifMouse.containsMouse
                icon: Common.Icons.icons.close
                danger: true
                onClicked: notifItem.dismissed()
            }
        }

        function formatTime(date) {
            if (!date) return ""
            const now = new Date()
            const diff = now - date
            const mins = Math.floor(diff / 60000)
            const hours = Math.floor(diff / 3600000)

            if (mins < 1) return "now"
            if (mins < 60) return mins + "m"
            if (hours < 24) return hours + "h"
            return date.toLocaleDateString()
        }
    }
}
