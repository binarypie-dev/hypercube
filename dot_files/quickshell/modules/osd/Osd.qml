import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../common" as Common
import "../../" as Root

// Vim-style minimal OSD with TUI aesthetics
PanelWindow {
    id: root

    required property var targetScreen
    screen: targetScreen

    // Position at top right, below status bar
    anchors.top: true
    anchors.right: true

    margins.top: Common.Appearance.sizes.barHeight + Common.Appearance.spacing.medium
    margins.right: Common.Appearance.spacing.medium

    property bool isTooltip: Root.GlobalStates.osdType === "tooltip"

    implicitWidth: isTooltip
        ? tooltipContent.implicitWidth + Common.Appearance.spacing.large * 2
        : Common.Appearance.sizes.osdWidth
    implicitHeight: isTooltip
        ? tooltipContent.implicitHeight + Common.Appearance.spacing.medium * 2
        : Common.Appearance.sizes.osdHeight

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "osd"

    visible: Root.GlobalStates.osdVisible

    // OSD background - TUI style with border
    Rectangle {
        id: osdBackground
        anchors.fill: parent

        opacity: Root.GlobalStates.osdVisible ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: Common.Appearance.animation.fast
                easing.type: Easing.OutCubic
            }
        }

        // Sharp corners, thin border - TUI style
        radius: Common.Appearance.rounding.tiny
        color: Qt.rgba(
            Common.Appearance.colors.bgDark.r,
            Common.Appearance.colors.bgDark.g,
            Common.Appearance.colors.bgDark.b,
            Common.Appearance.overlayOpacity
        )

        border.width: Common.Appearance.borderWidth.thin
        border.color: Common.Appearance.colors.border
    }

    // Tooltip content
    Text {
        id: tooltipContent
        visible: root.isTooltip
        anchors.centerIn: parent
        text: Root.GlobalStates.osdTooltipText
        font.family: Common.Appearance.fonts.mono
        font.pixelSize: Common.Appearance.fontSize.small
        color: Common.Appearance.colors.fg
    }

    // Progress OSD content (vim-style minimal)
    RowLayout {
        visible: !root.isTooltip
        anchors.fill: parent
        anchors.leftMargin: Common.Appearance.spacing.medium
        anchors.rightMargin: Common.Appearance.spacing.medium
        spacing: Common.Appearance.spacing.medium

        // Type indicator (like vim mode indicator)
        Rectangle {
            Layout.preferredWidth: typeLabel.implicitWidth + Common.Appearance.spacing.medium * 2
            Layout.preferredHeight: parent.height - Common.Appearance.spacing.small * 2
            color: getTypeColor()
            radius: Common.Appearance.rounding.tiny

            function getTypeColor() {
                if (Root.GlobalStates.osdMuted) {
                    return Common.Appearance.colors.error
                }
                switch (Root.GlobalStates.osdType) {
                    case "volume": return Common.Appearance.colors.blue
                    case "brightness": return Common.Appearance.colors.yellow
                    case "mic": return Common.Appearance.colors.green
                    default: return Common.Appearance.colors.magenta
                }
            }

            Text {
                id: typeLabel
                anchors.centerIn: parent
                text: getTypeText()
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.tiny
                font.bold: true
                color: Common.Appearance.colors.bg

                function getTypeText() {
                    if (Root.GlobalStates.osdMuted) {
                        return Root.GlobalStates.osdType === "mic" ? "MIC OFF" : "MUTED"
                    }
                    switch (Root.GlobalStates.osdType) {
                        case "volume": return "VOL"
                        case "brightness": return "BRI"
                        case "mic": return "MIC"
                        default: return "OSD"
                    }
                }
            }
        }

        // Progress bar (vim-style minimal)
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 4

            // Background track
            Rectangle {
                anchors.fill: parent
                radius: 2
                color: Common.Appearance.colors.bgVisual
            }

            // Progress fill
            Rectangle {
                width: parent.width * Math.min(Root.GlobalStates.osdValue, 1.0)
                height: parent.height
                radius: 2
                color: Root.GlobalStates.osdMuted
                    ? Common.Appearance.colors.error
                    : Common.Appearance.colors.fg

                Behavior on width {
                    NumberAnimation {
                        duration: Common.Appearance.animation.fast
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // Overshoot indicator
            Rectangle {
                visible: Root.GlobalStates.osdValue > 1.0 && Root.GlobalStates.osdType === "volume"
                x: parent.width
                width: Math.min((Root.GlobalStates.osdValue - 1.0) * parent.width, parent.width * 0.5)
                height: parent.height
                radius: 2
                color: Common.Appearance.colors.error
                opacity: 0.8

                Behavior on width {
                    NumberAnimation {
                        duration: Common.Appearance.animation.fast
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        // Value text (monospace, right-aligned)
        Text {
            Layout.preferredWidth: 40
            horizontalAlignment: Text.AlignRight
            text: Root.GlobalStates.osdMuted
                ? "---"
                : Math.round(Root.GlobalStates.osdValue * 100) + "%"
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.small
            color: Root.GlobalStates.osdMuted
                ? Common.Appearance.colors.error
                : Common.Appearance.colors.fgDark
        }
    }

    // Click to dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: Root.GlobalStates.osdVisible = false
    }
}
