import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray

import "../common" as Common
import "../../services" as Services
import "../../" as Root

// Lualine-inspired status bar with vim-style segments
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

    // Segment component - lualine style section
    component Segment: Rectangle {
        id: segment
        property string segmentText: ""
        property string icon: ""
        property color segmentColor: Common.Appearance.colors.bgHighlight
        property color textColor: Common.Appearance.colors.fg
        property bool showSeparator: true
        property bool isActive: false
        property bool clickable: false
        signal clicked()

        color: segmentColor
        implicitWidth: segmentContent.implicitWidth + Common.Appearance.spacing.medium * 2
        implicitHeight: parent.height

        RowLayout {
            id: segmentContent
            anchors.centerIn: parent
            spacing: Common.Appearance.spacing.small

            Common.Icon {
                visible: segment.icon !== ""
                name: segment.icon
                size: Common.Appearance.sizes.iconSmall
                color: segment.isActive ? Common.Appearance.colors.blue : segment.textColor
            }

            Text {
                visible: segment.segmentText !== ""
                text: segment.segmentText
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                font.bold: segment.isActive
                color: segment.isActive ? Common.Appearance.colors.blue : segment.textColor
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: segment.clickable
            cursorShape: segment.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
            hoverEnabled: segment.clickable
            onClicked: segment.clicked()

            Rectangle {
                anchors.fill: parent
                color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
            }
        }

        // Right separator
        Text {
            visible: segment.showSeparator
            anchors.right: parent.right
            anchors.rightMargin: -width / 2
            anchors.verticalCenter: parent.verticalCenter
            text: Common.Appearance.separators.right
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: parent.height
            color: segment.segmentColor
            z: 1
        }
    }

    // Icon-only segment for tray items
    component IconSegment: Rectangle {
        id: iconSeg
        property string icon: ""
        property color iconColor: Common.Appearance.colors.fgDark
        property color segmentColor: Common.Appearance.colors.bgHighlight
        property bool clickable: false
        property bool showBadge: false
        property color badgeColor: Common.Appearance.colors.error
        signal clicked()

        color: segmentColor
        implicitWidth: Common.Appearance.sizes.barHeight
        implicitHeight: parent.height

        Common.Icon {
            anchors.centerIn: parent
            name: iconSeg.icon
            size: Common.Appearance.sizes.iconSmall
            color: iconSeg.iconColor
        }

        // Badge indicator
        Rectangle {
            visible: iconSeg.showBadge
            width: 6
            height: 6
            radius: 3
            color: iconSeg.badgeColor
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 6
            anchors.rightMargin: 8
        }

        MouseArea {
            anchors.fill: parent
            enabled: iconSeg.clickable
            cursorShape: iconSeg.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
            hoverEnabled: iconSeg.clickable
            onClicked: iconSeg.clicked()

            Rectangle {
                anchors.fill: parent
                color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
            }
        }
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

    // Bar background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(
            Common.Appearance.colors.bgDark.r,
            Common.Appearance.colors.bgDark.g,
            Common.Appearance.colors.bgDark.b,
            Common.Appearance.panelOpacity
        )

        // Bottom border line
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 0
            color: Common.Appearance.colors.border
        }
    }

    // Bar content
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ═══════════════════════════════════════════════════════════════
        // LEFT SECTION - Mode indicator + navigation
        // ═══════════════════════════════════════════════════════════════

        // Mode indicator (vim-style)
        Rectangle {
            visible: root.isLeftmost
            color: root.modeColor
            implicitWidth: modeText.implicitWidth + Common.Appearance.spacing.large * 2
            implicitHeight: parent.height

            Text {
                id: modeText
                anchors.centerIn: parent
                text: root.modeDisplayText
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                font.bold: true
                color: Common.Appearance.colors.bg
            }

            // Powerline separator
            Text {
                anchors.left: parent.right
                anchors.leftMargin: -1
                anchors.verticalCenter: parent.verticalCenter
                text: Common.Appearance.separators.left
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: parent.height
                color: root.modeColor
                z: 1
            }
        }

        // Apps button
        IconSegment {
            visible: root.isLeftmost
            icon: Common.Icons.icons.apps
            segmentColor: Common.Appearance.colors.bgHighlight
            iconColor: Root.GlobalStates.sidebarLeftView === "apps" && Root.GlobalStates.sidebarLeftOpen
                ? Common.Appearance.colors.blue
                : Common.Appearance.colors.fgDark
            clickable: true
            onClicked: Root.GlobalStates.toggleSidebarLeft(root.targetScreen, "apps")
        }

        // Updates button
        MouseArea {
            id: updatesButton
            visible: root.isLeftmost
            implicitWidth: Common.Appearance.sizes.barHeight
            implicitHeight: parent.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Root.GlobalStates.toggleSidebarLeft(root.targetScreen, "updates")

            property bool isRunning: Services.Updates.preinstallRunning
            property bool needsAttention: Services.Updates.needsAttention

            Rectangle {
                anchors.fill: parent
                color: Common.Appearance.colors.bgHighlight

                Rectangle {
                    anchors.fill: parent
                    color: updatesButton.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                }
            }

            Common.Icon {
                anchors.centerIn: parent
                name: updatesButton.isRunning
                    ? Common.Icons.icons.refresh
                    : (updatesButton.needsAttention
                        ? Common.Icons.icons.download
                        : Common.Icons.icons.checkCircle)
                size: Common.Appearance.sizes.iconSmall
                color: updatesButton.needsAttention
                    ? Common.Appearance.colors.green
                    : Common.Appearance.colors.fgDark

                RotationAnimation on rotation {
                    running: updatesButton.isRunning
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }
        }

        // Separator after left section
        Rectangle {
            visible: root.isLeftmost
            width: 0
            height: parent.height
            color: Common.Appearance.colors.border
        }

        // ═══════════════════════════════════════════════════════════════
        // CENTER SECTION - Spacer (could show workspace info later)
        // ═══════════════════════════════════════════════════════════════
        Item { Layout.fillWidth: true }

        // ═══════════════════════════════════════════════════════════════
        // RIGHT SECTION - System indicators
        // ═══════════════════════════════════════════════════════════════

        // Separator before right section
        Rectangle {
            visible: root.isRightmost
            width: 0
            height: parent.height
            color: Common.Appearance.colors.border
        }

        // System tray
        RowLayout {
            visible: root.isRightmost
            spacing: 0

            Repeater {
                model: SystemTray.items

                delegate: MouseArea {
                    id: trayItemArea
                    required property var modelData

                    implicitWidth: Common.Appearance.sizes.barHeight
                    implicitHeight: Common.Appearance.sizes.barHeight
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

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

                    Rectangle {
                        anchors.fill: parent
                        color: Common.Appearance.colors.bgHighlight

                        Rectangle {
                            anchors.fill: parent
                            color: trayItemArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                        }
                    }

                    property bool primaryFailed: trayItemArea.hasCustomPath || primaryTrayIcon.status === Image.Error || primaryTrayIcon.status === Image.Null || trayItemArea.iconSource === ""

                    Image {
                        id: primaryTrayIcon
                        anchors.centerIn: parent
                        width: Common.Appearance.sizes.iconSmall
                        height: Common.Appearance.sizes.iconSmall
                        sourceSize: Qt.size(Common.Appearance.sizes.iconSmall, Common.Appearance.sizes.iconSmall)
                        source: trayItemArea.iconSource
                        smooth: true
                        visible: status === Image.Ready
                    }

                    Image {
                        id: fallbackTrayIcon
                        anchors.centerIn: parent
                        width: Common.Appearance.sizes.iconSmall
                        height: Common.Appearance.sizes.iconSmall
                        sourceSize: Qt.size(Common.Appearance.sizes.iconSmall, Common.Appearance.sizes.iconSmall)
                        source: trayItemArea.primaryFailed ? trayItemArea.datacubeIcon : ""
                        smooth: true
                        visible: trayItemArea.primaryFailed && status === Image.Ready
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: Common.Appearance.sizes.iconSmall
                        height: Common.Appearance.sizes.iconSmall
                        radius: Common.Appearance.rounding.tiny
                        color: Common.Appearance.colors.bgVisual
                        visible: trayItemArea.primaryFailed && fallbackTrayIcon.status !== Image.Ready

                        Text {
                            anchors.centerIn: parent
                            text: trayItemArea.modelData.title ? trayItemArea.modelData.title.charAt(0).toUpperCase() : "?"
                            font.pixelSize: 9
                            font.bold: true
                            color: Common.Appearance.colors.fg
                        }
                    }

                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton || (trayItemArea.modelData.onlyMenu && trayItemArea.modelData.hasMenu)) {
                            if (trayItemArea.modelData.hasMenu) {
                                const pos = trayItemArea.mapToItem(null, 0, trayItemArea.height)
                                trayItemArea.modelData.display(root, pos.x, pos.y)
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            trayItemArea.modelData.secondaryActivate()
                        } else {
                            trayItemArea.modelData.activate()
                        }
                    }

                    onWheel: (wheel) => {
                        trayItemArea.modelData.scroll(wheel.angleDelta.y, false)
                    }
                }
            }
        }

        // Separator
        Rectangle {
            visible: root.isRightmost && SystemTray.items.length > 0
            width: 0
            height: parent.height
            color: Common.Appearance.colors.border
        }

        // Camera Privacy indicator
        IconSegment {
            visible: root.isRightmost && Services.Privacy.cameraInUse
            icon: Common.Icons.icons.camera
            iconColor: Common.Appearance.colors.error
            segmentColor: Common.Appearance.colors.bgHighlight
        }

        // Audio segment (mic + speaker)
        MouseArea {
            visible: root.isRightmost
            implicitWidth: audioContent.implicitWidth + Common.Appearance.spacing.medium * 2
            implicitHeight: parent.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "audio")

            Rectangle {
                anchors.fill: parent
                color: Common.Appearance.colors.bgHighlight

                Rectangle {
                    anchors.fill: parent
                    color: parent.parent.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                }
            }

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
        }

        // Bluetooth
        IconSegment {
            visible: root.isRightmost && Services.BluetoothStatus.available
            icon: Services.BluetoothStatus.powered
                ? (Services.BluetoothStatus.connected
                    ? Common.Icons.icons.bluetoothConnected
                    : Common.Icons.icons.bluetooth)
                : Common.Icons.icons.bluetoothOff
            iconColor: Services.BluetoothStatus.connected
                ? Common.Appearance.colors.blue
                : (Services.BluetoothStatus.powered ? Common.Appearance.colors.fgDark : Common.Appearance.colors.comment)
            segmentColor: Common.Appearance.colors.bgHighlight
            clickable: true
            onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "bluetooth")
        }

        // Network
        IconSegment {
            visible: root.isRightmost && Common.Config.showNetwork
            icon: {
                if (!Services.Network.connected) {
                    return Services.Network.wifiAvailable ? Common.Icons.icons.wifiOff : Common.Icons.icons.ethernetOff
                }
                if (Services.Network.type === "wifi") {
                    return Common.Icons.wifiIcon(Services.Network.strength, true)
                }
                return Common.Icons.icons.ethernet
            }
            iconColor: Services.Network.connected ? Common.Appearance.colors.fgDark : Common.Appearance.colors.comment
            segmentColor: Common.Appearance.colors.bgHighlight
            clickable: true
            onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "network")
        }

        // Notifications
        IconSegment {
            visible: root.isRightmost
            icon: Root.GlobalStates.doNotDisturb
                ? Common.Icons.icons.doNotDisturb
                : Common.Icons.icons.notification
            iconColor: Root.GlobalStates.unreadNotificationCount > 0 && !Root.GlobalStates.doNotDisturb
                ? Common.Appearance.colors.orange
                : Common.Appearance.colors.fgDark
            segmentColor: Common.Appearance.colors.bgHighlight
            clickable: true
            showBadge: Root.GlobalStates.unreadNotificationCount > 0 && !Root.GlobalStates.doNotDisturb
            badgeColor: Common.Appearance.colors.orange
            onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "notifications")
        }

        // Separator before clock
        Rectangle {
            visible: root.isRightmost
            width: 0
            height: parent.height
            color: Common.Appearance.colors.border
        }

        // Clock segment (prominent)
        MouseArea {
            visible: root.isRightmost
            implicitWidth: clockContent.implicitWidth + Common.Appearance.spacing.large * 2
            implicitHeight: parent.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "calendar")

            Rectangle {
                anchors.fill: parent
                color: Common.Appearance.colors.bgHighlight

                Rectangle {
                    anchors.fill: parent
                    color: parent.parent.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                }
            }

            RowLayout {
                id: clockContent
                anchors.centerIn: parent
                spacing: Common.Appearance.spacing.small

                Text {
                    text: Services.DateTime.timeString
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.small
                    font.bold: true
                    color: Common.Appearance.colors.fg
                }

                Text {
                    text: Common.Appearance.separators.pipe
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Common.Appearance.colors.comment
                }

                Text {
                    text: Services.DateTime.shortDateString
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Common.Appearance.colors.fgDark
                }
            }

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

            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: Services.DateTime.update()
            }
        }

        // Weather segment (if enabled)
        MouseArea {
            visible: root.isRightmost && Common.Config.showWeather
            implicitWidth: weatherContent.implicitWidth + Common.Appearance.spacing.medium * 2
            implicitHeight: parent.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "weather")

            Rectangle {
                anchors.fill: parent
                color: Common.Appearance.colors.bgHighlight

                Rectangle {
                    anchors.fill: parent
                    color: parent.parent.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                }
            }

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
        }

        // Separator before power
        Rectangle {
            visible: root.isRightmost
            width: 0
            height: parent.height
            color: Common.Appearance.colors.border
        }

        // Power/Battery segment (rightmost, colored)
        MouseArea {
            visible: root.isRightmost
            implicitWidth: powerContent.implicitWidth + Common.Appearance.spacing.medium * 2
            implicitHeight: parent.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Root.GlobalStates.toggleSidebarRight(root.targetScreen, "power")

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

            Rectangle {
                anchors.fill: parent
                color: parent.powerColor

                Rectangle {
                    anchors.fill: parent
                    color: parent.parent.containsMouse ? Qt.rgba(0, 0, 0, 0.1) : "transparent"
                }
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
        }
    }
}
