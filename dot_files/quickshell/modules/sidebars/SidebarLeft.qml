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

    margins.top: Common.Appearance.sizes.barHeight

    implicitWidth: Common.Appearance.sizes.sidebarWidth
    color: "transparent"

    visible: Root.GlobalStates.sidebarLeftOpen

    // Request keyboard focus from compositor
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "sidebar"

    // Background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(
            Common.Appearance.m3colors.surface.r,
            Common.Appearance.m3colors.surface.g,
            Common.Appearance.m3colors.surface.b,
            Common.Appearance.panelOpacity
        )
    }

    // Application View (shown when sidebarLeftView === "apps")
    Loader {
        anchors.fill: parent
        anchors.margins: Common.Appearance.spacing.medium
        active: Root.GlobalStates.sidebarLeftView === "apps"
        source: "ApplicationView.qml"
    }

    // Update View (shown when sidebarLeftView === "updates")
    Loader {
        anchors.fill: parent
        anchors.margins: Common.Appearance.spacing.medium
        active: Root.GlobalStates.sidebarLeftView === "updates"
        source: "UpdateView.qml"
    }
}
