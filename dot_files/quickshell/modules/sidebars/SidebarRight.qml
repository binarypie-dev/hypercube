import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../common" as Common
import "../../services" as Services
import "../../" as Root

PanelWindow {
    id: root

    required property var targetScreen
    screen: targetScreen

    anchors {
        top: true
        bottom: true
        right: true
    }

    margins.top: Common.Appearance.sizes.barHeight

    implicitWidth: Common.Appearance.sizes.sidebarWidth
    color: "transparent"

    visible: Root.GlobalStates.sidebarRightOpen

    // Request keyboard focus from compositor
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "sidebar"

    // ==================== Component Definitions ====================
    // These must be defined before they are used

    // Notification item component
    component NotificationItem: MouseArea {
        id: notifItem
        property var notification: ({})
        signal dismissed()
        signal actionClicked(string actionId)

        Layout.fillWidth: true
        Layout.preferredHeight: notifContent.implicitHeight + Common.Appearance.spacing.medium * 2
        hoverEnabled: true

        Rectangle {
            anchors.fill: parent
            radius: Common.Appearance.rounding.medium
            color: notifItem.containsMouse
                ? Common.Appearance.surfaceLayer(2)
                : "transparent"

            RowLayout {
                id: notifContent
                anchors.fill: parent
                anchors.margins: Common.Appearance.spacing.small
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

                    // Query datacube immediately if we have an app name (don't wait for Qt to fail)
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

                    // Primary: Try datacube icon first (more reliable for flatpaks)
                    Image {
                        id: datacubeNotifIcon
                        anchors.fill: parent
                        source: notifIconContainer.datacubeIcon
                        sourceSize: Qt.size(32, 32)
                        smooth: true
                        visible: status === Image.Ready
                    }

                    // Fallback 1: Qt icon provider with notification's appIcon
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

                    // Actions
                    RowLayout {
                        visible: notification.actions && notification.actions.length > 0
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

                    Text {
                        anchors.centerIn: parent
                        text: Common.Icons.icons.close
                        font.family: Common.Appearance.fonts.icon
                        font.pixelSize: Common.Appearance.sizes.iconSmall
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

    // ==================== UI ====================

    // Background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(
            Common.Appearance.m3colors.surface.r,
            Common.Appearance.m3colors.surface.g,
            Common.Appearance.m3colors.surface.b,
            Common.Appearance.panelOpacity
        )

        // Left border
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Common.Appearance.m3colors.outlineVariant
        }
    }

    // Bluetooth View (shown when sidebarRightView === "bluetooth")
    Loader {
        anchors.fill: parent
        anchors.margins: Common.Appearance.spacing.medium
        active: Root.GlobalStates.sidebarRightView === "bluetooth"
        source: "BluetoothView.qml"
    }

    // Audio View (shown when sidebarRightView === "audio")
    Loader {
        anchors.fill: parent
        anchors.margins: Common.Appearance.spacing.medium
        active: Root.GlobalStates.sidebarRightView === "audio"
        source: "AudioView.qml"
    }

    // Default Content (shown when sidebarRightView === "default")
    Flickable {
        visible: Root.GlobalStates.sidebarRightView === "default"
        anchors.fill: parent
        anchors.margins: Common.Appearance.spacing.medium
        contentHeight: contentColumn.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: Common.Appearance.spacing.large

            // Quick Settings section
            SidebarSection {
                title: "Quick Settings"

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Common.Appearance.spacing.small

                    // Quick toggles row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Common.Appearance.spacing.small

                        // Only show WiFi toggle if WiFi hardware is available
                        QuickToggle {
                            visible: Services.Network.wifiAvailable
                            icon: Services.Network.connected && Services.Network.type === "wifi"
                                ? Common.Icons.icons.wifi
                                : Common.Icons.icons.wifiOff
                            label: "WiFi"
                            active: Services.Network.connected && Services.Network.type === "wifi"
                            onClicked: {
                                // Would toggle wifi
                            }
                        }

                        // Show ethernet status if ethernet is available
                        QuickToggle {
                            visible: Services.Network.ethernetAvailable && !Services.Network.wifiAvailable
                            icon: Services.Network.connected && Services.Network.type === "ethernet"
                                ? Common.Icons.icons.ethernet
                                : Common.Icons.icons.ethernetOff
                            label: "Ethernet"
                            active: Services.Network.connected && Services.Network.type === "ethernet"
                            onClicked: {
                                // Ethernet is usually always on
                            }
                        }

                    }

                    // Do Not Disturb toggle
                    SwitchToggle {
                        Layout.fillWidth: true
                        icon: Root.GlobalStates.doNotDisturb
                            ? Common.Icons.icons.doNotDisturb
                            : Common.Icons.icons.notification
                        label: "Do Not Disturb"
                        active: Root.GlobalStates.doNotDisturb
                        onToggled: Root.GlobalStates.doNotDisturb = !Root.GlobalStates.doNotDisturb
                    }

                }
            }

            // Calendar section
            SidebarSection {
                title: Services.DateTime.dateString

                CalendarWidget {
                    Layout.fillWidth: true
                }
            }

            // Weather section (if enabled)
            Loader {
                Layout.fillWidth: true
                active: Common.Config.showWeather && Services.Weather.ready
                sourceComponent: SidebarSection {
                    title: "Weather"

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Common.Appearance.spacing.medium

                        Text {
                            text: Services.Weather.icon
                            font.family: Common.Appearance.fonts.icon
                            font.pixelSize: 48
                            color: Common.Appearance.m3colors.primary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: Services.Weather.temperature
                                font.family: Common.Appearance.fonts.main
                                font.pixelSize: Common.Appearance.fontSize.headline
                                font.weight: Font.Medium
                                color: Common.Appearance.m3colors.onSurface
                            }

                            Text {
                                text: Services.Weather.condition
                                font.family: Common.Appearance.fonts.main
                                font.pixelSize: Common.Appearance.fontSize.normal
                                color: Common.Appearance.m3colors.onSurfaceVariant
                            }

                            Text {
                                text: Services.Weather.location
                                font.family: Common.Appearance.fonts.main
                                font.pixelSize: Common.Appearance.fontSize.small
                                color: Common.Appearance.m3colors.onSurfaceVariant
                            }
                        }
                    }
                }
            }

            // Notifications section
            SidebarSection {
                title: "Notifications (" + Services.Notifications.notifications.length + ")"
                action: Services.Notifications.notifications.length > 0 ? "Clear all" : ""
                onActionClicked: {
                    Services.Notifications.clearAll()
                    Root.GlobalStates.unreadNotificationCount = 0
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Common.Appearance.spacing.small

                    // Empty state
                    Text {
                        visible: Services.Notifications.notifications.length === 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "No notifications"
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.normal
                        color: Common.Appearance.m3colors.onSurfaceVariant
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

            // Bottom spacer
            Item { Layout.preferredHeight: Common.Appearance.spacing.medium }
        }
    }

    // Section component
    component SidebarSection: ColumnLayout {
        property string title: ""
        property string action: ""
        signal actionClicked()

        default property alias content: sectionContent.data

        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: title
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.small
                font.weight: Font.Medium
                color: Common.Appearance.m3colors.onSurfaceVariant
                textFormat: Text.PlainText
            }

            Item { Layout.fillWidth: true }

            MouseArea {
                visible: action !== ""
                Layout.preferredWidth: actionText.implicitWidth
                Layout.preferredHeight: actionText.implicitHeight
                cursorShape: Qt.PointingHandCursor
                onClicked: actionClicked()

                Text {
                    id: actionText
                    text: action
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Common.Appearance.m3colors.primary
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: sectionContent.implicitHeight + Common.Appearance.spacing.medium * 2
            radius: Common.Appearance.rounding.large
            color: Common.Appearance.m3colors.surfaceVariant

            ColumnLayout {
                id: sectionContent
                anchors.fill: parent
                anchors.margins: Common.Appearance.spacing.medium
            }
        }
    }

    // Quick toggle button
    component QuickToggle: MouseArea {
        property string icon: ""
        property string label: ""
        property bool active: false

        Layout.fillWidth: true
        Layout.preferredHeight: 72
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        Rectangle {
            anchors.fill: parent
            radius: Common.Appearance.rounding.medium
            color: active
                ? Common.Appearance.m3colors.primaryContainer
                : (parent.containsMouse
                    ? Common.Appearance.surfaceLayer(2)
                    : Common.Appearance.surfaceLayer(1))

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Common.Appearance.spacing.tiny

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: icon
                    font.family: Common.Appearance.fonts.icon
                    font.pixelSize: Common.Appearance.sizes.iconLarge
                    color: active
                        ? Common.Appearance.m3colors.onPrimaryContainer
                        : Common.Appearance.m3colors.onSurface
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: label
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: active
                        ? Common.Appearance.m3colors.onPrimaryContainer
                        : Common.Appearance.m3colors.onSurfaceVariant
                }
            }
        }
    }

    // Toggle with switch (matches Bluetooth style)
    component SwitchToggle: Rectangle {
        id: switchToggle
        property string icon: ""
        property string label: ""
        property string sublabel: ""
        property bool active: false
        signal toggled()

        Layout.fillWidth: true
        Layout.preferredHeight: 56
        radius: Common.Appearance.rounding.large
        color: Common.Appearance.m3colors.surfaceVariant

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Common.Appearance.spacing.medium
            anchors.rightMargin: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            Text {
                text: switchToggle.icon
                font.family: Common.Appearance.fonts.icon
                font.pixelSize: Common.Appearance.sizes.iconLarge
                color: switchToggle.active
                    ? Common.Appearance.m3colors.primary
                    : Common.Appearance.m3colors.onSurfaceVariant
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: switchToggle.label
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.normal
                    font.weight: Font.Medium
                    color: Common.Appearance.m3colors.onSurface
                }

                Text {
                    text: switchToggle.sublabel || (switchToggle.active ? "On" : "Off")
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Common.Appearance.m3colors.onSurfaceVariant
                }
            }

            // Modern rounded switch
            MouseArea {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 32
                cursorShape: Qt.PointingHandCursor
                onClicked: switchToggle.toggled()

                Rectangle {
                    id: switchTrack
                    anchors.fill: parent
                    radius: height / 2
                    color: switchToggle.active
                        ? Common.Appearance.m3colors.primary
                        : Common.Appearance.m3colors.surfaceVariant
                    border.width: switchToggle.active ? 0 : 2
                    border.color: Common.Appearance.m3colors.outline

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Rectangle {
                        id: switchThumb
                        width: switchToggle.active ? 24 : 16
                        height: switchToggle.active ? 24 : 16
                        radius: height / 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: switchToggle.active ? parent.width - width - 4 : 4
                        color: switchToggle.active
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

    // Slider control
    component SliderControl: Item {
        id: sliderControl
        property string icon: ""
        property string label: ""
        property real value: 0.5
        signal userValueChanged(real newValue)

        Layout.fillWidth: true
        Layout.preferredHeight: 40

        RowLayout {
            anchors.fill: parent
            spacing: Common.Appearance.spacing.small

            Text {
                text: sliderControl.icon
                font.family: Common.Appearance.fonts.icon
                font.pixelSize: Common.Appearance.sizes.iconMedium
                color: Common.Appearance.m3colors.onSurface
            }

            Slider {
                id: slider
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                from: 0
                to: 1
                value: sliderControl.value

                // Only emit when user is actively changing
                onMoved: sliderControl.userValueChanged(value)

                background: Rectangle {
                    x: slider.leftPadding
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    width: slider.availableWidth
                    height: 6
                    radius: 3
                    color: Common.Appearance.m3colors.surfaceVariant

                    Rectangle {
                        width: slider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: Common.Appearance.m3colors.primary
                    }
                }

                handle: Rectangle {
                    x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    width: 20
                    height: 20
                    radius: 10
                    color: slider.pressed
                        ? Common.Appearance.m3colors.primary
                        : Common.Appearance.m3colors.primaryContainer
                    border.width: 2
                    border.color: Common.Appearance.m3colors.primary
                }
            }

            Text {
                text: Math.round(sliderControl.value * 100) + "%"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.m3colors.onSurfaceVariant
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    // Calendar widget
    component CalendarWidget: Item {
        Layout.fillWidth: true
        Layout.preferredHeight: calendarGrid.implicitHeight + 48

        property int displayMonth: new Date().getMonth()
        property int displayYear: new Date().getFullYear()

        ColumnLayout {
            anchors.fill: parent
            spacing: Common.Appearance.spacing.small

            // Month navigation
            RowLayout {
                Layout.fillWidth: true

                MouseArea {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (displayMonth === 0) {
                            displayMonth = 11
                            displayYear--
                        } else {
                            displayMonth--
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Common.Icons.icons.back
                        font.family: Common.Appearance.fonts.icon
                        font.pixelSize: Common.Appearance.sizes.iconMedium
                        color: Common.Appearance.m3colors.onSurface
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Services.DateTime.monthNames[displayMonth] + " " + displayYear
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.normal
                    font.weight: Font.Medium
                    color: Common.Appearance.m3colors.onSurface
                }

                MouseArea {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (displayMonth === 11) {
                            displayMonth = 0
                            displayYear++
                        } else {
                            displayMonth++
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Common.Icons.icons.forward
                        font.family: Common.Appearance.fonts.icon
                        font.pixelSize: Common.Appearance.sizes.iconMedium
                        color: Common.Appearance.m3colors.onSurface
                    }
                }
            }

            // Day headers
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.m3colors.onSurfaceVariant
                    }
                }
            }

            // Calendar grid
            Grid {
                id: calendarGrid
                Layout.fillWidth: true
                columns: 7
                spacing: 2

                Repeater {
                    model: 42

                    Rectangle {
                        width: (parent.width - 12) / 7
                        height: width
                        radius: width / 2

                        property int dayNumber: {
                            const firstDay = new Date(displayYear, displayMonth, 1).getDay()
                            const daysInMonth = new Date(displayYear, displayMonth + 1, 0).getDate()
                            const dayIndex = index - firstDay + 1

                            if (dayIndex < 1 || dayIndex > daysInMonth) {
                                return 0
                            }
                            return dayIndex
                        }

                        property bool isToday: {
                            const now = new Date()
                            return dayNumber === now.getDate() &&
                                   displayMonth === now.getMonth() &&
                                   displayYear === now.getFullYear()
                        }

                        color: isToday
                            ? Common.Appearance.m3colors.primary
                            : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: dayNumber > 0 ? dayNumber : ""
                            font.family: Common.Appearance.fonts.main
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: isToday
                                ? Common.Appearance.m3colors.onPrimary
                                : Common.Appearance.m3colors.onSurface
                        }
                    }
                }
            }
        }
    }
}
