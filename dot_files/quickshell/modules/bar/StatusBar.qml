import QtQuick
import Quickshell
import Quickshell.Wayland

import "../common" as Common
import "../../services" as Services
import "../../" as Root

// Status line: a thin gradient strip along the top of every screen. All the
// detail (tray, clock, network, audio, ...) lives in the hub; the line only
// signals state at a glance:
//   left end   blue, or the hub's mode color while it's open,
//              orange while the microphone or camera is in use
//   right end  purple, orange when there are unread notifications
// The gradient fades to black in the middle and spans all monitors (the left
// end on the leftmost screen, the right end on the rightmost).
PanelWindow {
    id: root

    required property var targetScreen
    screen: targetScreen

    anchors {
        top: true
        left: true
        right: true
    }

    // Reserve the line's height so windows never cover it
    implicitHeight: Common.Appearance.sizes.barHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "statusbar"

    readonly property bool privacyActive: Services.Privacy.micInUse || Services.Privacy.cameraInUse
    readonly property bool hasUnread: Root.GlobalStates.unreadNotificationCount > 0
        && !Root.GlobalStates.doNotDisturb

    readonly property color hubColor: Root.GlobalStates.currentHubTab.insert
        ? Common.Appearance.colors.modeInsert
        : Common.Appearance.colors.modeVisual

    readonly property color leftColor: {
        if (privacyActive) return Common.Appearance.colors.orange
        if (Root.GlobalStates.hubOpen) return hubColor
        return Common.Appearance.colors.modeNormal
    }

    readonly property color rightColor: hasUnread
        ? Common.Appearance.colors.orange
        : Common.Appearance.colors.magenta

    readonly property bool isLeftmost: Quickshell.screens.length === 1
        || targetScreen === Root.GlobalStates.leftmostScreen
    readonly property bool isRightmost: Quickshell.screens.length === 1
        || targetScreen === Root.GlobalStates.rightmostScreen

    readonly property color blackColor: Qt.rgba(0, 0, 0, 1)

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0.0
                color: root.isLeftmost ? root.leftColor : root.blackColor

                Behavior on color {
                    ColorAnimation {
                        duration: Common.Appearance.animation.fast
                        easing.type: Common.Appearance.easing.standard
                    }
                }
            }
            GradientStop {
                position: 0.5
                color: root.blackColor
            }
            GradientStop {
                position: 1.0
                color: root.isRightmost ? root.rightColor : root.blackColor

                Behavior on color {
                    ColorAnimation {
                        duration: Common.Appearance.animation.fast
                        easing.type: Common.Appearance.easing.standard
                    }
                }
            }
        }
    }
}
