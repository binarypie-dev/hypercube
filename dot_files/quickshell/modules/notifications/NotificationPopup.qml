import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../common" as Common
import "../../" as Root
import "../../services" as Services

// Notification popup that appears in the corner
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

    // Notification list
    property var notifications: []
    property int maxVisible: 5

    // Background
    Rectangle {
        anchors.fill: parent
        radius: Common.Appearance.rounding.large
        color: "transparent"
    }

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

        // "More notifications" indicator
        Rectangle {
            visible: notifications.length > maxVisible
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: Common.Appearance.rounding.medium
            color: Qt.rgba(
                Common.Appearance.m3colors.surface.r,
                Common.Appearance.m3colors.surface.g,
                Common.Appearance.m3colors.surface.b,
                Common.Appearance.overlayOpacity
            )

            Text {
                anchors.centerIn: parent
                text: "+" + (notifications.length - maxVisible) + " more notifications"
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.m3colors.onSurfaceVariant
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Root.GlobalStates.sidebarRightOpen = true
            }
        }
    }

    // Notification item component
    component NotificationItem: Rectangle {
        id: notifItem

        property var notification
        signal dismissed()
        signal actionInvoked(string actionId)

        implicitHeight: contentLayout.implicitHeight + Common.Appearance.spacing.medium * 2
        radius: Common.Appearance.rounding.large
        color: Qt.rgba(
            Common.Appearance.m3colors.surface.r,
            Common.Appearance.m3colors.surface.g,
            Common.Appearance.m3colors.surface.b,
            Common.Appearance.overlayOpacity
        )

        border.width: 1
        border.color: Common.Appearance.m3colors.outlineVariant

        // Auto-dismiss timer
        Timer {
            id: dismissTimer
            interval: Common.Config.notificationTimeout
            running: true
            onTriggered: dismissed()
        }

        // Click to invoke default action, hover to pause timer
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
                // If there's exactly one action, clicking the notification invokes it
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

            // Header row
            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.small

                // App icon with datacube fallback
                Item {
                    id: popupIconContainer
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20

                    property string iconName: notification.appIcon || ""
                    property string datacubeIcon: ""
                    property bool datacubeQueried: false
                    property bool iconLoaded: datacubePopupIcon.status === Image.Ready || primaryPopupIcon.status === Image.Ready
                    visible: iconLoaded

                    Component.onCompleted: {
                        if (notification.appName && !datacubeQueried) {
                            datacubeQueried = true
                            popupIconLookup.query = notification.appName
                            popupIconLookup.running = true
                        }
                    }

                    Process {
                        id: popupIconLookup
                        property string query: ""
                        command: ["bash", "-lc", "datacube-cli query '" + query.replace(/'/g, "'\\''") + "' --json -m 1"]

                        stdout: SplitParser {
                            splitMarker: "\n"
                            onRead: data => {
                                if (!data || data.trim() === "") return
                                try {
                                    const item = JSON.parse(data)
                                    if (item.icon) {
                                        if (item.icon.startsWith("/")) {
                                            popupIconContainer.datacubeIcon = "file://" + item.icon
                                        } else {
                                            popupIconContainer.datacubeIcon = "image://icon/" + item.icon
                                        }
                                    }
                                } catch (e) {}
                            }
                        }
                    }

                    // Primary: Try datacube icon first
                    Image {
                        id: datacubePopupIcon
                        anchors.fill: parent
                        source: popupIconContainer.datacubeIcon
                        sourceSize: Qt.size(20, 20)
                        smooth: true
                        visible: status === Image.Ready
                    }

                    // Fallback: Qt icon provider
                    Image {
                        id: primaryPopupIcon
                        anchors.fill: parent
                        source: popupIconContainer.iconName && datacubePopupIcon.status !== Image.Ready
                            ? "image://icon/" + popupIconContainer.iconName
                            : ""
                        sourceSize: Qt.size(20, 20)
                        smooth: true
                        visible: datacubePopupIcon.status !== Image.Ready && status === Image.Ready
                    }
                }

                // App name
                Text {
                    Layout.fillWidth: true
                    text: notification.appName || "Notification"
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Common.Appearance.m3colors.onSurfaceVariant
                    elide: Text.ElideRight
                }

                // Time
                Text {
                    text: formatTime(notification.time)
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.smallest
                    color: Common.Appearance.m3colors.onSurfaceVariant
                }

                // Close button
                MouseArea {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    cursorShape: Qt.PointingHandCursor
                    onClicked: dismissed()

                    Common.Icon {
                        anchors.centerIn: parent
                        name: Common.Icons.icons.close
                        size: Common.Appearance.sizes.iconSmall
                        color: Common.Appearance.m3colors.onSurfaceVariant
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
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    source: notification.image || ""
                    sourceSize: Qt.size(48, 48)
                    fillMode: Image.PreserveAspectCrop
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    // Summary
                    Text {
                        Layout.fillWidth: true
                        text: notification.summary || ""
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.normal
                        font.weight: Font.Medium
                        color: Common.Appearance.m3colors.onSurface
                        elide: Text.ElideRight
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                    }

                    // Body
                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: notification.body || ""
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.m3colors.onSurfaceVariant
                        elide: Text.ElideRight
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                    }
                }
            }

            // Actions row - only show if multiple actions (single action is triggered by clicking notification)
            RowLayout {
                visible: notification.actions && notification.actions.length > 1
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.small

                Repeater {
                    model: notification.actions || []

                    delegate: MouseArea {
                        required property var modelData
                        Layout.preferredHeight: 28
                        Layout.preferredWidth: actionText.implicitWidth + Common.Appearance.spacing.medium * 2
                        cursorShape: Qt.PointingHandCursor
                        onClicked: actionInvoked(modelData.identifier || "")

                        Rectangle {
                            anchors.fill: parent
                            radius: Common.Appearance.rounding.small
                            color: parent.containsMouse
                                ? Common.Appearance.m3colors.primaryContainer
                                : Common.Appearance.m3colors.surfaceVariant
                        }

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: modelData.text || "Action"
                            font.family: Common.Appearance.fonts.main
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.m3colors.primary
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
        // Add to front of list
        notifications = [notification, ...notifications]
        Root.GlobalStates.unreadNotificationCount++
    }

    function removeNotification(id: var) {
        notifications = notifications.filter(n => n.id !== id)
    }

    function invokeAction(notification: var, actionId: string) {
        // Invoke action through the notification service
        Services.Notifications.invokeAction(notification.id, actionId)
        removeNotification(notification.id)
    }

    function clearAll() {
        notifications = []
        Root.GlobalStates.unreadNotificationCount = 0
    }
}
