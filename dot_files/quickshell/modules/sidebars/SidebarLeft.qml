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
        left: true
    }

    // Flush to all edges (status bar is on overlay layer above)
    margins.top: 0
    margins.bottom: 5
    margins.left: 0

    implicitWidth: Common.Appearance.sizes.sidebarWidth
    color: "transparent"

    visible: Root.GlobalStates.sidebarLeftOpen

    onVisibleChanged: {
        if (visible && appViewLoader.item) {
            appViewLoader.item.focusSearch()
        }
    }

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "sidebar"

    // Mode color for borders (matches status bar)
    property color modeColor: {
        if (Root.GlobalStates.sidebarLeftView === "apps") return Common.Appearance.colors.modeInsert
        if (Root.GlobalStates.sidebarLeftView === "updates") return Common.Appearance.colors.modeInsert
        return Common.Appearance.colors.modeNormal
    }

    property color blackColor: Qt.rgba(0, 0, 0, 1)

    // Panel container with transparent black background
    Rectangle {
        id: panelBackground
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.75)

        // Right border with gradient (black at top -> active at corner)
        Rectangle {
            id: rightBorder
            anchors.right: parent.right
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

        // Content area - positioned below status bar and above bottom border
        Item {
            anchors.fill: parent
            anchors.topMargin: 1
            anchors.leftMargin: 0
            anchors.rightMargin: Common.Appearance.spacing.medium
            anchors.bottomMargin: 1
            clip: true

            // Application View
            Loader {
                id: appViewLoader
                anchors.fill: parent
                active: Root.GlobalStates.sidebarLeftView === "apps"
                source: "ApplicationView.qml"
                onLoaded: item.focusSearch()
            }

            // Update View
            Loader {
                anchors.fill: parent
                active: Root.GlobalStates.sidebarLeftView === "updates"
                source: "UpdateView.qml"
            }
        }
    }
}
