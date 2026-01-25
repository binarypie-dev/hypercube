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

    margins.top: Common.Appearance.sizes.barHeight + Common.Appearance.spacing.small
    margins.bottom: Common.Appearance.spacing.small
    margins.left: Common.Appearance.spacing.small

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

    // TUI Panel container
    Common.TuiPanel {
        anchors.fill: parent
        title: Root.GlobalStates.sidebarLeftView === "apps" ? "[ Applications ]" : "[ System Updates ]"
        keyHints: [
            { key: "Esc", action: "close" },
            { key: "/", action: "search" },
            { key: "j/k", action: "navigate" },
            { key: "Enter", action: "select" }
        ]

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
