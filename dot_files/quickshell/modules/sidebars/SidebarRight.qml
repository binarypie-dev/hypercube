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

    // Allow keyboard focus for text input in sidebars
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

    // Network View (shown when sidebarRightView === "network")
    Loader {
        anchors.fill: parent
        anchors.margins: Common.Appearance.spacing.medium
        active: Root.GlobalStates.sidebarRightView === "network"
        source: "NetworkView.qml"
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

    // Calendar View (shown when sidebarRightView === "calendar")
    Loader {
        anchors.fill: parent
        anchors.margins: Common.Appearance.spacing.medium
        active: Root.GlobalStates.sidebarRightView === "calendar"
        source: "CalendarView.qml"
    }

    // Notifications View (shown when sidebarRightView === "notifications")
    Loader {
        anchors.fill: parent
        anchors.margins: Common.Appearance.spacing.medium
        active: Root.GlobalStates.sidebarRightView === "notifications"
        source: "NotificationsView.qml"
    }

    // Power View (shown when sidebarRightView === "power")
    Loader {
        anchors.fill: parent
        anchors.margins: Common.Appearance.spacing.medium
        active: Root.GlobalStates.sidebarRightView === "power"
        source: "PowerView.qml"
    }

    // Weather View (shown when sidebarRightView === "weather")
    Loader {
        anchors.fill: parent
        anchors.margins: Common.Appearance.spacing.medium
        active: Root.GlobalStates.sidebarRightView === "weather"
        source: "WeatherView.qml"
    }

    // Default Content (shown when sidebarRightView === "default")
    Loader {
        anchors.fill: parent
        anchors.margins: Common.Appearance.spacing.medium
        active: Root.GlobalStates.sidebarRightView === "default"
        source: "DefaultView.qml"
    }
}
