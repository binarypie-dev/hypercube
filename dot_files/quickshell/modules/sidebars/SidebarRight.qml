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

    // Flush to all edges (status bar is on overlay layer above)
    margins.top: 0
    margins.bottom: 5
    margins.right: 0

    implicitWidth: Common.Appearance.sizes.sidebarWidth
    color: "transparent"

    visible: Root.GlobalStates.sidebarRightOpen

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "sidebar"

    // Mode color for borders (matches status bar)
    property color modeColor: {
        switch (Root.GlobalStates.sidebarRightView) {
            case "audio":
            case "bluetooth":
            case "network":
            case "calendar":
            case "notifications":
            case "power":
            case "weather":
                return Common.Appearance.colors.modeVisual
            default:
                return Common.Appearance.colors.modeNormal
        }
    }

    property color blackColor: Qt.rgba(0, 0, 0, 1)

    // Panel container with transparent black background
    Rectangle {
        id: panelBackground
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.75)

        // Left border with gradient (black at top -> active at corner)
        Rectangle {
            id: leftBorder
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                    position: 0.0
                    color: root.blackColor
                }
                GradientStop {
                    position: 0.85
                    color: root.modeColor

                    Behavior on color {
                        ColorAnimation {
                            duration: Common.Appearance.animation.fast
                            easing.type: Common.Appearance.easing.standard
                        }
                    }
                }
                GradientStop {
                    position: 1.0
                    color: root.modeColor

                    Behavior on color {
                        ColorAnimation {
                            duration: Common.Appearance.animation.fast
                            easing.type: Common.Appearance.easing.standard
                        }
                    }
                }
            }
        }

        // Bottom border with gradient (active at corner -> black at edge)
        Rectangle {
            id: bottomBorder
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: root.modeColor

                    Behavior on color {
                        ColorAnimation {
                            duration: Common.Appearance.animation.fast
                            easing.type: Common.Appearance.easing.standard
                        }
                    }
                }
                GradientStop {
                    position: 0.15
                    color: root.modeColor

                    Behavior on color {
                        ColorAnimation {
                            duration: Common.Appearance.animation.fast
                            easing.type: Common.Appearance.easing.standard
                        }
                    }
                }
                GradientStop {
                    position: 1.0
                    color: root.blackColor
                }
            }
        }

        // Content area - positioned below status bar and above bottom border
        Item {
            anchors.fill: parent
            anchors.topMargin: 1
            anchors.leftMargin: Common.Appearance.spacing.medium
            anchors.rightMargin: 0
            anchors.bottomMargin: 1
            clip: true

            // Network View
            Loader {
                anchors.fill: parent
                active: Root.GlobalStates.sidebarRightView === "network"
                source: "NetworkView.qml"
            }

            // Bluetooth View
            Loader {
                anchors.fill: parent
                active: Root.GlobalStates.sidebarRightView === "bluetooth"
                source: "BluetoothView.qml"
            }

            // Audio View
            Loader {
                anchors.fill: parent
                active: Root.GlobalStates.sidebarRightView === "audio"
                source: "AudioView.qml"
            }

            // Calendar View
            Loader {
                anchors.fill: parent
                active: Root.GlobalStates.sidebarRightView === "calendar"
                source: "CalendarView.qml"
            }

            // Notifications View
            Loader {
                anchors.fill: parent
                active: Root.GlobalStates.sidebarRightView === "notifications"
                source: "NotificationsView.qml"
            }

            // Power View
            Loader {
                anchors.fill: parent
                active: Root.GlobalStates.sidebarRightView === "power"
                source: "PowerView.qml"
            }

            // Weather View
            Loader {
                anchors.fill: parent
                active: Root.GlobalStates.sidebarRightView === "weather"
                source: "WeatherView.qml"
            }

            // Default Content
            Loader {
                anchors.fill: parent
                active: Root.GlobalStates.sidebarRightView === "default"
                source: "DefaultView.qml"
            }
        }
    }
}
