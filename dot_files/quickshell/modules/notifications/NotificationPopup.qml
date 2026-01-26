import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../common" as Common
import "../../" as Root
import "../../services" as Services

// Vim-style notification popup with TUI aesthetics
PanelWindow {
    id: root

    required property var targetScreen
    screen: targetScreen

    anchors {
        top: true
        right: true
    }

    margins.top: Common.Appearance.sizes.barHeight + Common.Appearance.spacing.medium
    margins.right: Common.Appearance.spacing.medium

    implicitWidth: Common.Appearance.sizes.notificationWidth
    implicitHeight: notificationColumn.implicitHeight
    color: "transparent"

    visible: notifications.length > 0 && !Root.GlobalStates.doNotDisturb

    property var notifications: []
    property int maxVisible: 5

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notification"

    ColumnLayout {
        id: notificationColumn
        anchors.fill: parent
        spacing: Common.Appearance.spacing.small

        Repeater {
            model: notifications.slice(0, maxVisible)

            delegate: NotificationItem {
                Layout.fillWidth: true
                notification: modelData
                onDismissed: removeNotification(modelData.id)
                onActionInvoked: (actionId) => invokeAction(modelData, actionId)
            }
        }

        // "More notifications" indicator (TUI style)
        Rectangle {
            visible: notifications.length > maxVisible
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            radius: Common.Appearance.rounding.tiny
            color: Qt.rgba(
                Common.Appearance.colors.bgDark.r,
                Common.Appearance.colors.bgDark.g,
                Common.Appearance.colors.bgDark.b,
                Common.Appearance.overlayOpacity
            )
            border.width: Common.Appearance.borderWidth.thin
            border.color: Common.Appearance.colors.border

            Text {
                anchors.centerIn: parent
                text: "-- +" + (notifications.length - maxVisible) + " more --"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.tiny
                color: Common.Appearance.colors.comment
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "notifications")
            }
        }
    }

    // Notification item component (TUI style)
    component NotificationItem: Rectangle {
        id: notifItem

        property var notification
        signal dismissed()
        signal actionInvoked(string actionId)

        implicitHeight: contentLayout.implicitHeight + Common.Appearance.spacing.medium * 2
        radius: Common.Appearance.rounding.tiny
        color: Qt.rgba(
            Common.Appearance.colors.bgDark.r,
            Common.Appearance.colors.bgDark.g,
            Common.Appearance.colors.bgDark.b,
            Common.Appearance.overlayOpacity
        )

        border.width: Common.Appearance.borderWidth.thin
        border.color: Common.Appearance.colors.border

        // Auto-dismiss timer
        Timer {
            id: dismissTimer
            interval: Common.Config.notificationTimeout
            running: true
            onTriggered: dismissed()
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: notification.actions && notification.actions.length === 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
            onContainsMouseChanged: {
                if (containsMouse) {
                    dismissTimer.stop()
                } else {
                    dismissTimer.restart()
                }
            }
            onClicked: {
                if (notification.actions && notification.actions.length === 1) {
                    actionInvoked(notification.actions[0].identifier || "")
                }
            }
        }

        ColumnLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.small

            // Header row (vim-style)
            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.small

                // App icon
                Item {
                    id: popupIconContainer
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16

                    property string resolvedIcon: notification.appName ? Services.IconResolver.getIcon(notification.appName) : ""
                    property string fallbackIcon: notification.appIcon || ""
                    property string iconSource: resolvedIcon || (fallbackIcon ? "image://icon/" + fallbackIcon : "")

                    visible: appIcon.status === Image.Ready

                    Image {
                        id: appIcon
                        anchors.fill: parent
                        source: popupIconContainer.iconSource
                        sourceSize: Qt.size(16, 16)
                        smooth: true
                    }
                }

                // App name (bracketed, vim-style)
                Text {
                    text: "[" + (notification.appName || "notify") + "]"
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.tiny
                    font.bold: true
                    color: Common.Appearance.colors.cyan
                }

                Item { Layout.fillWidth: true }

                // Time
                Text {
                    text: formatTime(notification.time)
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.tiny
                    color: Common.Appearance.colors.comment
                }

                // Close button
                MouseArea {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    cursorShape: Qt.PointingHandCursor
                    onClicked: dismissed()

                    Rectangle {
                        anchors.fill: parent
                        radius: Common.Appearance.rounding.tiny
                        color: parent.containsMouse ? Common.Appearance.colors.bgVisual : "transparent"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.small
                        font.bold: true
                        color: parent.containsMouse ? Common.Appearance.colors.error : Common.Appearance.colors.comment
                    }
                }
            }

            // Content row
            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.medium

                // Notification image
                Image {
                    visible: notification.image && status === Image.Ready
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    source: notification.image || ""
                    sourceSize: Qt.size(40, 40)
                    fillMode: Image.PreserveAspectCrop
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    // Summary
                    Text {
                        Layout.fillWidth: true
                        text: notification.summary || ""
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.small
                        font.bold: true
                        color: Common.Appearance.colors.fg
                        elide: Text.ElideRight
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                    }

                    // Body
                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: notification.body || ""
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.tiny
                        color: Common.Appearance.colors.fgDark
                        elide: Text.ElideRight
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                    }
                }
            }

            // Actions row (TUI style buttons)
            RowLayout {
                visible: notification.actions && notification.actions.length > 1
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.small

                Repeater {
                    model: notification.actions || []

                    delegate: MouseArea {
                        required property var modelData
                        Layout.preferredHeight: 22
                        Layout.preferredWidth: actionText.implicitWidth + Common.Appearance.spacing.medium * 2
                        cursorShape: Qt.PointingHandCursor
                        onClicked: actionInvoked(modelData.identifier || "")

                        Rectangle {
                            anchors.fill: parent
                            radius: Common.Appearance.rounding.tiny
                            color: parent.containsMouse
                                ? Common.Appearance.colors.bgVisual
                                : Common.Appearance.colors.bgHighlight
                            border.width: Common.Appearance.borderWidth.thin
                            border.color: parent.containsMouse
                                ? Common.Appearance.colors.blue
                                : Common.Appearance.colors.border
                        }

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: "[" + (modelData.text || "Action") + "]"
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.tiny
                            color: parent.containsMouse
                                ? Common.Appearance.colors.blue
                                : Common.Appearance.colors.fgDark
                        }
                    }
                }
            }
        }
    }

    function formatTime(timestamp: var): string {
        if (!timestamp) return ""
        const now = new Date()
        const then = new Date(timestamp)
        const diff = Math.floor((now - then) / 1000)

        if (diff < 60) return "now"
        if (diff < 3600) return Math.floor(diff / 60) + "m"
        if (diff < 86400) return Math.floor(diff / 3600) + "h"
        return then.toLocaleDateString()
    }

    function addNotification(notification: var) {
        notifications = [notification, ...notifications]
        Root.GlobalStates.unreadNotificationCount++
    }

    function removeNotification(id: var) {
        notifications = notifications.filter(n => n.id !== id)
    }

    function invokeAction(notification: var, actionId: string) {
        Services.Notifications.invokeAction(notification.id, actionId)
        removeNotification(notification.id)
    }

    function clearAll() {
        notifications = []
        Root.GlobalStates.unreadNotificationCount = 0
    }
}
