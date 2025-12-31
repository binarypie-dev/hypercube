import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

import "../common" as Common
import "../../services" as Services
import "../../" as Root

// Notifications view for the right sidebar
ColumnLayout {
    id: root
    spacing: Common.Appearance.spacing.large

    // Header with clear all and close button
    RowLayout {
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        Text {
            Layout.fillWidth: true
            text: "Notifications"
            font.family: Common.Appearance.fonts.main
            font.pixelSize: Common.Appearance.fontSize.headline
            font.weight: Font.Medium
            color: Common.Appearance.m3colors.onSurface
        }

        MouseArea {
            visible: Services.Notifications.notifications.length > 0
            Layout.preferredWidth: clearText.implicitWidth + Common.Appearance.spacing.medium * 2
            Layout.preferredHeight: 32
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: {
                Services.Notifications.clearAll()
                Root.GlobalStates.unreadNotificationCount = 0
            }

            Rectangle {
                anchors.fill: parent
                radius: Common.Appearance.rounding.small
                color: parent.containsMouse ? Common.Appearance.m3colors.surfaceVariant : "transparent"
            }

            Text {
                id: clearText
                anchors.centerIn: parent
                text: "Clear all"
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.m3colors.primary
            }
        }

        MouseArea {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: Root.GlobalStates.sidebarRightOpen = false

            Rectangle {
                anchors.fill: parent
                radius: Common.Appearance.rounding.small
                color: parent.containsMouse ? Common.Appearance.m3colors.surfaceVariant : "transparent"
            }

            Common.Icon {
                anchors.centerIn: parent
                name: Common.Icons.icons.close
                size: Common.Appearance.sizes.iconMedium
                color: Common.Appearance.m3colors.onSurface
            }
        }
    }

    // Do Not Disturb toggle card
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: dndContent.implicitHeight + Common.Appearance.spacing.medium * 2
        radius: Common.Appearance.rounding.large
        color: Common.Appearance.m3colors.surfaceVariant

        RowLayout {
            id: dndContent
            anchors.fill: parent
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            Common.Icon {
                name: Root.GlobalStates.doNotDisturb
                    ? Common.Icons.icons.doNotDisturb
                    : Common.Icons.icons.notification
                size: Common.Appearance.sizes.iconLarge
                color: Root.GlobalStates.doNotDisturb
                    ? Common.Appearance.m3colors.primary
                    : Common.Appearance.m3colors.onSurfaceVariant
            }

            ColumnLayout {
                spacing: 2

                Text {
                    text: "Do Not Disturb"
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.normal
                    font.weight: Font.Medium
                    color: Common.Appearance.m3colors.onSurface
                }

                Text {
                    text: Root.GlobalStates.doNotDisturb ? "On" : "Off"
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Common.Appearance.m3colors.onSurfaceVariant
                }
            }

            Item { Layout.fillWidth: true }

            // Modern rounded switch
            MouseArea {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignRight
                cursorShape: Qt.PointingHandCursor
                onClicked: Root.GlobalStates.doNotDisturb = !Root.GlobalStates.doNotDisturb

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Root.GlobalStates.doNotDisturb
                        ? Common.Appearance.m3colors.primary
                        : Common.Appearance.m3colors.surfaceVariant
                    border.width: Root.GlobalStates.doNotDisturb ? 0 : 2
                    border.color: Common.Appearance.m3colors.outline

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Rectangle {
                        width: Root.GlobalStates.doNotDisturb ? 24 : 16
                        height: Root.GlobalStates.doNotDisturb ? 24 : 16
                        radius: height / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: Root.GlobalStates.doNotDisturb ? parent.width - width - 4 : 4
                        color: Root.GlobalStates.doNotDisturb
                            ? Common.Appearance.m3colors.onPrimary
                            : Common.Appearance.m3colors.outline

                        Behavior on x {
                            NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                        }
                        Behavior on width {
                            NumberAnimation { duration: 150 }
                        }
                        Behavior on height {
                            NumberAnimation { duration: 150 }
                        }
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }
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
        }

        ColumnLayout {
            id: notificationsColumn
            width: parent.width
            spacing: Common.Appearance.spacing.small

            // Empty state
            Rectangle {
                visible: Services.Notifications.notifications.length === 0
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                radius: Common.Appearance.rounding.large
                color: Common.Appearance.m3colors.surfaceVariant

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Common.Appearance.spacing.small

                    Common.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        name: Common.Icons.icons.notification
                        size: 32
                        color: Common.Appearance.m3colors.onSurfaceVariant
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No notifications"
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.normal
                        color: Common.Appearance.m3colors.onSurfaceVariant
                    }
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
    component NotificationItem: MouseArea {
        id: notifItem
        property var notification: ({})
        signal dismissed()
        signal actionClicked(string actionId)

        // Check if notification has exactly one action (clicking notification will invoke it)
        property bool hasSingleAction: notification.actions && notification.actions.length === 1

        Layout.fillWidth: true
        Layout.preferredHeight: notifContent.implicitHeight + Common.Appearance.spacing.medium * 2
        hoverEnabled: true
        cursorShape: hasSingleAction ? Qt.PointingHandCursor : Qt.ArrowCursor

        onClicked: {
            // If there's exactly one action, clicking the notification invokes it
            if (hasSingleAction) {
                actionClicked(notification.actions[0].identifier || "")
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Common.Appearance.rounding.large
            color: Common.Appearance.m3colors.surfaceVariant

            RowLayout {
                id: notifContent
                anchors.fill: parent
                anchors.margins: Common.Appearance.spacing.medium
                spacing: Common.Appearance.spacing.small

                // App icon with datacube fallback
                Item {
                    id: notifIconContainer
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    Layout.alignment: Qt.AlignTop

                    property string iconName: notification.appIcon || ""
                    property string datacubeIcon: ""
                    property bool datacubeQueried: false

                    Component.onCompleted: {
                        if (notification.appName && !datacubeQueried) {
                            datacubeQueried = true
                            iconLookup.query = notification.appName
                            iconLookup.running = true
                        }
                    }

                    Process {
                        id: iconLookup
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
                                            notifIconContainer.datacubeIcon = "file://" + item.icon
                                        } else {
                                            notifIconContainer.datacubeIcon = "image://icon/" + item.icon
                                        }
                                    }
                                } catch (e) {
                                    console.log("Icon lookup parse error:", e)
                                }
                            }
                        }
                    }

                    // Primary: Try datacube icon first
                    Image {
                        id: datacubeNotifIcon
                        anchors.fill: parent
                        source: notifIconContainer.datacubeIcon
                        sourceSize: Qt.size(32, 32)
                        smooth: true
                        visible: status === Image.Ready
                    }

                    // Fallback 1: Qt icon provider
                    Image {
                        id: primaryNotifIcon
                        anchors.fill: parent
                        source: notifIconContainer.iconName && datacubeNotifIcon.status !== Image.Ready
                            ? "image://icon/" + notifIconContainer.iconName
                            : ""
                        sourceSize: Qt.size(32, 32)
                        smooth: true
                        visible: datacubeNotifIcon.status !== Image.Ready && status === Image.Ready
                    }

                    // Fallback 2: Letter icon
                    Rectangle {
                        anchors.fill: parent
                        visible: datacubeNotifIcon.status !== Image.Ready && primaryNotifIcon.status !== Image.Ready
                        radius: Common.Appearance.rounding.small
                        color: Common.Appearance.m3colors.primaryContainer

                        Text {
                            anchors.centerIn: parent
                            text: notification.appName ? notification.appName.charAt(0).toUpperCase() : "?"
                            font.pixelSize: 14
                            font.bold: true
                            color: Common.Appearance.m3colors.onPrimaryContainer
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
                            font.family: Common.Appearance.fonts.main
                            font.pixelSize: Common.Appearance.fontSize.normal
                            font.weight: Font.Medium
                            color: Common.Appearance.m3colors.onSurface
                            elide: Text.ElideRight
                        }

                        Text {
                            text: notifItem.formatTime(notification.time)
                            font.family: Common.Appearance.fonts.main
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.m3colors.onSurfaceVariant
                        }
                    }

                    // Body
                    Text {
                        visible: notification.body && notification.body !== ""
                        Layout.fillWidth: true
                        text: notification.body
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.m3colors.onSurfaceVariant
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }

                    // Actions - only show if multiple actions (single action is triggered by clicking notification)
                    RowLayout {
                        visible: notification.actions && notification.actions.length > 1
                        Layout.fillWidth: true
                        spacing: Common.Appearance.spacing.small

                        Repeater {
                            model: notification.actions || []

                            MouseArea {
                                required property var modelData
                                Layout.preferredHeight: 28
                                Layout.preferredWidth: actionLabel.implicitWidth + Common.Appearance.spacing.medium * 2
                                cursorShape: Qt.PointingHandCursor
                                onClicked: notifItem.actionClicked(modelData.identifier || "")

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Common.Appearance.rounding.small
                                    color: Common.Appearance.m3colors.primaryContainer

                                    Text {
                                        id: actionLabel
                                        anchors.centerIn: parent
                                        text: modelData.text || "Action"
                                        font.family: Common.Appearance.fonts.main
                                        font.pixelSize: Common.Appearance.fontSize.small
                                        color: Common.Appearance.m3colors.onPrimaryContainer
                                    }
                                }
                            }
                        }
                    }
                }

                // Dismiss button
                MouseArea {
                    visible: notifItem.containsMouse
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignTop
                    cursorShape: Qt.PointingHandCursor
                    onClicked: notifItem.dismissed()

                    Common.Icon {
                        anchors.centerIn: parent
                        name: Common.Icons.icons.close
                        size: Common.Appearance.sizes.iconSmall
                        color: Common.Appearance.m3colors.onSurfaceVariant
                    }
                }
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
