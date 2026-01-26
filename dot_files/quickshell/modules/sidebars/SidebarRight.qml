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

    margins.bottom: Common.Appearance.spacing.small

    implicitWidth: Common.Appearance.sizes.sidebarWidth
    color: "transparent"

    visible: Root.GlobalStates.sidebarRightOpen

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "sidebar"

    // TUI Panel container
    Common.TuiPanel {
        anchors.fill: parent

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
