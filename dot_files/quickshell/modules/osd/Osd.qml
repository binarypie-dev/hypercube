import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../common" as Common
import "../../" as Root

PanelWindow {
    id: root

    required property var targetScreen
    screen: targetScreen

    // Center at the bottom of the screen
    anchors.bottom: true

    // Use margins to center horizontally
    margins.bottom: 100

    implicitWidth: Common.Appearance.sizes.osdWidth
    implicitHeight: Common.Appearance.sizes.osdHeight + Common.Appearance.spacing.large
    color: "transparent"

    // Float on top of windows without reserving space
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "osd"

    visible: Root.GlobalStates.osdVisible

    // OSD background
    Rectangle {
        id: osdBackground
        anchors.fill: parent

        // Animation for showing/hiding
        opacity: Root.GlobalStates.osdVisible ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: Common.Appearance.animation.standard
                easing.type: Easing.OutCubic
            }
        }
        radius: Common.Appearance.rounding.large
        color: Qt.rgba(
            Common.Appearance.m3colors.surface.r,
            Common.Appearance.m3colors.surface.g,
            Common.Appearance.m3colors.surface.b,
            Common.Appearance.overlayOpacity
        )

        // Border
        border.width: 1
        border.color: Common.Appearance.m3colors.outlineVariant
    }

    // OSD content
    RowLayout {
        anchors.fill: parent
        anchors.margins: Common.Appearance.spacing.medium
        spacing: Common.Appearance.spacing.medium

        // Icon
        Common.Icon {
            id: osdIcon
            name: getIcon()
            size: Common.Appearance.sizes.iconXLarge
            color: getIconColor()

            function getIcon() {
                switch (Root.GlobalStates.osdType) {
                    case "volume":
                        return Root.GlobalStates.osdMuted
                            ? Common.Icons.icons.volumeMute
                            : Common.Icons.volumeIcon(Root.GlobalStates.osdValue * 100, false)
                    case "brightness":
                        return Common.Icons.brightnessIcon(Root.GlobalStates.osdValue * 100)
                    case "mic":
                        return Root.GlobalStates.osdMuted
                            ? Common.Icons.icons.micOff
                            : Common.Icons.icons.mic
                    default:
                        return Common.Icons.icons.volumeHigh
                }
            }

            function getIconColor() {
                if (Root.GlobalStates.osdMuted) {
                    return Common.Appearance.m3colors.error
                }
                return Common.Appearance.m3colors.primary
            }
        }

        // Progress bar and value
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Common.Appearance.spacing.tiny

            // Progress bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                radius: 3
                color: Common.Appearance.m3colors.surfaceVariant

                Rectangle {
                    width: parent.width * Math.min(Root.GlobalStates.osdValue, 1.0)
                    height: parent.height
                    radius: parent.radius
                    color: Root.GlobalStates.osdMuted
                        ? Common.Appearance.m3colors.error
                        : Common.Appearance.m3colors.primary

                    Behavior on width {
                        NumberAnimation {
                            duration: 100
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                // Overshoot indicator (for volume > 100%)
                Rectangle {
                    visible: Root.GlobalStates.osdValue > 1.0 && Root.GlobalStates.osdType === "volume"
                    x: parent.width
                    width: Math.min((Root.GlobalStates.osdValue - 1.0) * parent.width, parent.width * 0.5)
                    height: parent.height
                    radius: parent.radius
                    color: Common.Appearance.m3colors.error
                    opacity: 0.7

                    Behavior on width {
                        NumberAnimation {
                            duration: 100
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Value text (if enabled)
            Text {
                visible: Common.Config.osdShowValue
                Layout.alignment: Qt.AlignRight
                text: getValueText()
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.m3colors.onSurfaceVariant

                function getValueText() {
                    if (Root.GlobalStates.osdMuted) {
                        return Root.GlobalStates.osdType === "mic" ? "Muted" : "Muted"
                    }
                    return Math.round(Root.GlobalStates.osdValue * 100) + "%"
                }
            }
        }
    }

    // Mouse area to dismiss on click
    MouseArea {
        anchors.fill: parent
        onClicked: Root.GlobalStates.osdVisible = false
    }
}
