import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray

import "../common" as Common
import "../../services" as Services
import "../../" as Root

// Status bar with two rounded pill sections
PanelWindow {
    id: root

    required property var targetScreen
    screen: targetScreen

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Common.Appearance.sizes.barHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "statusbar"

    // Current "mode" based on shell state
    property string currentMode: {
        if (Root.GlobalStates.sidebarLeftOpen) {
            return Root.GlobalStates.sidebarLeftView === "apps" ? "APPS" : "UPDATES"
        }
        if (Root.GlobalStates.sidebarRightOpen) {
            switch (Root.GlobalStates.sidebarRightView) {
                case "audio": return "AUDIO"
                case "bluetooth": return "BLUETOOTH"
                case "network": return "NETWORK"
                case "calendar": return "CALENDAR"
                case "notifications": return "NOTIFY"
                case "power": return "POWER"
                case "weather": return "WEATHER"
                default: return "NORMAL"
            }
        }
        return "NORMAL"
    }

    // Display text for mode indicator (shows all active workspaces when in NORMAL mode)
    property string modeDisplayText: currentMode === "NORMAL" ? Services.Hyprland.allWorkspaces : currentMode

    property color modeColor: {
        if (currentMode === "NORMAL") return Common.Appearance.colors.modeNormal
        if (currentMode === "APPS" || currentMode === "UPDATES") return Common.Appearance.colors.modeInsert
        return Common.Appearance.colors.modeVisual
    }

    // Helper properties for screen position
    property bool isLeftmost: {
        if (Quickshell.screens.length === 1) return true
        return targetScreen === Root.GlobalStates.leftmostScreen
    }
    property bool isRightmost: {
        if (Quickshell.screens.length === 1) return true
        return targetScreen === Root.GlobalStates.rightmostScreen
    }

    // Pill dimensions - use window rounding to match Hyprland
    property int pillHeight: Common.Appearance.sizes.barHeight
    property int pillRadius: Common.Appearance.rounding.window

    // Bar content - two pills at edges (margins match Hyprland gaps_out)
    Item {
        anchors.fill: parent
        anchors.topMargin: 2
        anchors.bottomMargin: 0
        anchors.leftMargin: 20
        anchors.rightMargin: 20

        // ═══════════════════════════════════════════════════════════════
        // LEFT PILL - Mode indicator + apps + updates
        // ═══════════════════════════════════════════════════════════════
        Rectangle {
            id: leftPill
            visible: root.isLeftmost
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: root.pillHeight
            width: leftPillContent.implicitWidth
            radius: root.pillRadius
            color: Qt.rgba(
                Common.Appearance.colors.bgDark.r,
                Common.Appearance.colors.bgDark.g,
                Common.Appearance.colors.bgDark.b,
                Common.Appearance.panelOpacity
            )
            border.width: 1
            border.color: Common.Appearance.colors.border
            clip: true

            RowLayout {
                id: leftPillContent
                anchors.fill: parent
                spacing: 0

                // Mode indicator
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: modeText.implicitWidth + Common.Appearance.spacing.medium * 2
                    color: root.modeColor
                    radius: root.pillRadius

                    // Square off the right side
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: root.pillRadius
                        color: parent.color
                    }

                    Text {
                        id: modeText
                        anchors.centerIn: parent
                        text: root.modeDisplayText
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.small
                        font.bold: true
                        color: Common.Appearance.colors.bg
                    }
                }

                // Apps button
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.pillHeight
                    color: "transparent"

                    Common.Icon {
                        anchors.centerIn: parent
                        name: Common.Icons.icons.apps
                        size: Common.Appearance.sizes.iconSmall
                        color: Root.GlobalStates.sidebarLeftView === "apps" && Root.GlobalStates.sidebarLeftOpen
                            ? Common.Appearance.colors.blue
                            : Common.Appearance.colors.fgDark
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Root.GlobalStates.toggleSidebarLeft(root.targetScreen, "apps")

                        Rectangle {
                            anchors.fill: parent
                            color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        }
                    }
                }

                // Updates button
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.pillHeight
                    color: "transparent"
                    radius: root.pillRadius

                    // Square off the left side
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: root.pillRadius
                        color: parent.color
                    }

                    property bool isRunning: Services.Updates.preinstallRunning ?? false
                    property bool needsAttention: Services.Updates.needsAttention ?? false

                    Common.Icon {
                        anchors.centerIn: parent
                        name: parent.isRunning
                            ? Common.Icons.icons.refresh
                            : (parent.needsAttention
                                ? Common.Icons.icons.download
                                : Common.Icons.icons.checkCircle)
                        size: Common.Appearance.sizes.iconSmall
                        color: parent.needsAttention
                            ? Common.Appearance.colors.green
                            : Common.Appearance.colors.fgDark

                        RotationAnimation on rotation {
                            running: Services.Updates.preinstallRunning ?? false
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Root.GlobalStates.toggleSidebarLeft(root.targetScreen, "updates")

                        Rectangle {
                            anchors.fill: parent
                            radius: root.pillRadius
                            color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: root.pillRadius
                                color: parent.color
                            }
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════
        // RIGHT PILL - System indicators
        // ═══════════════════════════════════════════════════════════════
        Rectangle {
            id: rightPill
            visible: root.isRightmost
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: root.pillHeight
            width: rightPillContent.implicitWidth
            radius: root.pillRadius
            color: Qt.rgba(
                Common.Appearance.colors.bgDark.r,
                Common.Appearance.colors.bgDark.g,
                Common.Appearance.colors.bgDark.b,
                Common.Appearance.panelOpacity
            )
            border.width: 1
            border.color: Common.Appearance.colors.border
            clip: true

            RowLayout {
                id: rightPillContent
                anchors.fill: parent
                spacing: 0

                // System tray
                Repeater {
                    model: SystemTray.items

                    delegate: Rectangle {
                        id: trayItemRect
                        required property var modelData
                        required property int index

                        Layout.fillHeight: true
                        Layout.preferredWidth: root.pillHeight
                        color: "transparent"
                        radius: index === 0 ? root.pillRadius : 0

                        property bool hasCustomPath: modelData.icon && modelData.icon.includes("?path=")

                        property string iconSource: {
                            const icon = modelData.icon
                            if (!icon || icon === "") return ""
                            if (icon.includes("?path=")) return ""
                            if (icon.startsWith("/")) return "file://" + icon
                            if (icon.startsWith("file://") || icon.startsWith("image://")) return icon
                            return "image://icon/" + icon
                        }

                        property string datacubeIcon: Services.IconResolver.getIcon(modelData.title)
                        property bool primaryFailed: hasCustomPath || primaryTrayIcon.status === Image.Error || primaryTrayIcon.status === Image.Null || iconSource === ""

                        Image {
                            id: primaryTrayIcon
                            anchors.centerIn: parent
                            width: Common.Appearance.sizes.iconSmall
                            height: Common.Appearance.sizes.iconSmall
                            sourceSize: Qt.size(Common.Appearance.sizes.iconSmall, Common.Appearance.sizes.iconSmall)
                            source: trayItemRect.iconSource
                            smooth: true
                            visible: status === Image.Ready
                        }

                        Image {
                            id: fallbackTrayIcon
                            anchors.centerIn: parent
                            width: Common.Appearance.sizes.iconSmall
                            height: Common.Appearance.sizes.iconSmall
                            sourceSize: Qt.size(Common.Appearance.sizes.iconSmall, Common.Appearance.sizes.iconSmall)
                            source: trayItemRect.primaryFailed ? trayItemRect.datacubeIcon : ""
                            smooth: true
                            visible: trayItemRect.primaryFailed && status === Image.Ready
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: Common.Appearance.sizes.iconSmall
                            height: Common.Appearance.sizes.iconSmall
                            radius: Common.Appearance.rounding.tiny
                            color: Common.Appearance.colors.bgVisual
                            visible: trayItemRect.primaryFailed && fallbackTrayIcon.status !== Image.Ready

                            Text {
                                anchors.centerIn: parent
                                text: trayItemRect.modelData.title ? trayItemRect.modelData.title.charAt(0).toUpperCase() : "?"
                                font.pixelSize: 9
                                font.bold: true
                                color: Common.Appearance.colors.fg
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton || (trayItemRect.modelData.onlyMenu && trayItemRect.modelData.hasMenu)) {
                                    if (trayItemRect.modelData.hasMenu) {
                                        const pos = trayItemRect.mapToItem(null, 0, trayItemRect.height)
                                        trayItemRect.modelData.display(root, pos.x, pos.y)
                                    }
                                } else if (mouse.button === Qt.MiddleButton) {
                                    trayItemRect.modelData.secondaryActivate()
                                } else {
                                    trayItemRect.modelData.activate()
                                }
                            }

                            onWheel: (wheel) => {
                                trayItemRect.modelData.scroll(wheel.angleDelta.y, false)
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            }
                        }
                    }
                }

                // Separator after tray
                Rectangle {
                    visible: SystemTray.items.length > 0
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    Layout.topMargin: 6
                    Layout.bottomMargin: 6
                    color: Common.Appearance.colors.border
                }

                // Camera Privacy indicator
                Rectangle {
                    visible: Services.Privacy.cameraInUse
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.pillHeight
                    color: "transparent"

                    Common.Icon {
                        anchors.centerIn: parent
                        name: Common.Icons.icons.camera
                        size: Common.Appearance.sizes.iconSmall
                        color: Common.Appearance.colors.error
                    }
                }

                // Audio segment
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: audioContent.implicitWidth + Common.Appearance.spacing.medium * 2
                    color: "transparent"

                    RowLayout {
                        id: audioContent
                        anchors.centerIn: parent
                        spacing: Common.Appearance.spacing.small

                        Common.Icon {
                            name: Services.Audio.micMuted
                                ? Common.Icons.icons.micOff
                                : Common.Icons.icons.mic
                            size: Common.Appearance.sizes.iconSmall
                            color: Services.Privacy.micInUse
                                ? Common.Appearance.colors.error
                                : (Services.Audio.micMuted ? Common.Appearance.colors.comment : Common.Appearance.colors.fgDark)
                        }

                        Common.Icon {
                            name: Services.Audio.muted
                                ? Common.Icons.icons.volumeOff
                                : Common.Icons.volumeIcon(Services.Audio.volume * 100, false)
                            size: Common.Appearance.sizes.iconSmall
                            color: Services.Audio.muted ? Common.Appearance.colors.comment : Common.Appearance.colors.fgDark
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "audio")

                        Rectangle {
                            anchors.fill: parent
                            color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        }
                    }
                }

                // Bluetooth
                Rectangle {
                    visible: Services.BluetoothStatus.available
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.pillHeight
                    color: "transparent"

                    Common.Icon {
                        anchors.centerIn: parent
                        name: Services.BluetoothStatus.powered
                            ? (Services.BluetoothStatus.connected
                                ? Common.Icons.icons.bluetoothConnected
                                : Common.Icons.icons.bluetooth)
                            : Common.Icons.icons.bluetoothOff
                        size: Common.Appearance.sizes.iconSmall
                        color: Services.BluetoothStatus.connected
                            ? Common.Appearance.colors.blue
                            : (Services.BluetoothStatus.powered ? Common.Appearance.colors.fgDark : Common.Appearance.colors.comment)
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "bluetooth")

                        Rectangle {
                            anchors.fill: parent
                            color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        }
                    }
                }

                // Network
                Rectangle {
                    visible: Common.Config.showNetwork
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.pillHeight
                    color: "transparent"

                    Common.Icon {
                        anchors.centerIn: parent
                        name: {
                            if (!Services.Network.connected) {
                                return Services.Network.wifiAvailable ? Common.Icons.icons.wifiOff : Common.Icons.icons.ethernetOff
                            }
                            if (Services.Network.type === "wifi") {
                                return Common.Icons.wifiIcon(Services.Network.strength, true)
                            }
                            return Common.Icons.icons.ethernet
                        }
                        size: Common.Appearance.sizes.iconSmall
                        color: Services.Network.connected ? Common.Appearance.colors.fgDark : Common.Appearance.colors.comment
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "network")

                        Rectangle {
                            anchors.fill: parent
                            color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        }
                    }
                }

                // Notifications
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.pillHeight
                    color: "transparent"

                    Common.Icon {
                        anchors.centerIn: parent
                        name: Root.GlobalStates.doNotDisturb
                            ? Common.Icons.icons.doNotDisturb
                            : Common.Icons.icons.notification
                        size: Common.Appearance.sizes.iconSmall
                        color: Root.GlobalStates.unreadNotificationCount > 0 && !Root.GlobalStates.doNotDisturb
                            ? Common.Appearance.colors.orange
                            : Common.Appearance.colors.fgDark
                    }

                    // Badge
                    Rectangle {
                        visible: Root.GlobalStates.unreadNotificationCount > 0 && !Root.GlobalStates.doNotDisturb
                        width: 6
                        height: 6
                        radius: 3
                        color: Common.Appearance.colors.orange
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: 4
                        anchors.rightMargin: 6
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "notifications")

                        Rectangle {
                            anchors.fill: parent
                            color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        }
                    }
                }

                // Clock segment
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: clockContent.implicitWidth + Common.Appearance.spacing.medium * 2
                    color: "transparent"

                    RowLayout {
                        id: clockContent
                        anchors.centerIn: parent
                        spacing: Common.Appearance.spacing.small

                        Text {
                            text: Services.DateTime.shortDateString
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.small
                            font.bold: true
                            color: Common.Appearance.colors.fg
                        }

                        Text {
                            text: Common.Appearance.separators.pipe
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.colors.bgHighlight
                        }

                        Text {
                            text: Services.DateTime.timeString
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.colors.fgDark
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "calendar")

                        onContainsMouseChanged: {
                            if (containsMouse) {
                                Root.GlobalStates.osdType = "tooltip"
                                Root.GlobalStates.osdTooltipText = Services.DateTime.fullDateTimeString
                                Root.GlobalStates.osdVisible = true
                            } else {
                                if (Root.GlobalStates.osdType === "tooltip") {
                                    Root.GlobalStates.osdVisible = false
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        }
                    }

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        triggeredOnStart: true
                        onTriggered: Services.DateTime.update()
                    }
                }

                // Weather segment
                Rectangle {
                    visible: Common.Config.showWeather
                    Layout.fillHeight: true
                    Layout.preferredWidth: weatherContent.implicitWidth + Common.Appearance.spacing.medium * 2
                    color: "transparent"

                    RowLayout {
                        id: weatherContent
                        anchors.centerIn: parent
                        spacing: Common.Appearance.spacing.small

                        Common.Icon {
                            name: Services.Weather.ready
                                ? Common.Icons.weatherIcon(Services.Weather.condition, Services.Weather.isNight)
                                : Common.Icons.icons.cloudy
                            size: Common.Appearance.sizes.iconSmall
                            color: Common.Appearance.colors.cyan
                        }

                        Text {
                            text: Services.Weather.ready ? Services.Weather.temperature : "--°"
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.colors.fgDark
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "weather")

                        Rectangle {
                            anchors.fill: parent
                            color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        }
                    }
                }

                // Power/Battery segment (rightmost, colored)
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: powerContent.implicitWidth + Common.Appearance.spacing.medium * 2
                    radius: root.pillRadius
                    color: powerColor

                    // Square off the left side
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: root.pillRadius
                        color: parent.color
                    }

                    property color powerColor: {
                        if (Services.Battery.present) {
                            if (Services.Battery.percent <= 20 && !Services.Battery.charging) {
                                return Common.Appearance.colors.error
                            }
                            if (Services.Battery.pluggedIn) {
                                return Common.Appearance.colors.green
                            }
                        }
                        return Common.Appearance.colors.magenta
                    }

                    RowLayout {
                        id: powerContent
                        anchors.centerIn: parent
                        spacing: Common.Appearance.spacing.small

                        Common.Icon {
                            name: {
                                if (Services.Battery.present) {
                                    if (Services.Battery.pluggedIn && Services.Battery.percent >= 95) {
                                        return Common.Icons.icons.plug
                                    } else if (Services.Battery.charging) {
                                        return Common.Icons.icons.batteryCharging
                                    } else {
                                        return Common.Icons.batteryIcon(Services.Battery.percent, false)
                                    }
                                }
                                return Common.Icons.icons.power
                            }
                            size: Common.Appearance.sizes.iconSmall
                            color: Common.Appearance.colors.bg
                        }

                        Text {
                            visible: Services.Battery.present
                            text: Services.Battery.percent + "%"
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.small
                            font.bold: true
                            color: Common.Appearance.colors.bg
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "power")

                        Rectangle {
                            anchors.fill: parent
                            radius: root.pillRadius
                            color: parent.containsMouse ? Qt.rgba(0, 0, 0, 0.1) : "transparent"

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: root.pillRadius
                                color: parent.color
                            }
                        }
                    }
                }
            }
        }
    }
}
