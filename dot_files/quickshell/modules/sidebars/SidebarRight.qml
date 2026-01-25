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

    margins.top: Common.Appearance.sizes.barHeight + Common.Appearance.spacing.small
    margins.bottom: Common.Appearance.spacing.small
    margins.right: Common.Appearance.spacing.small

    implicitWidth: Common.Appearance.sizes.sidebarWidth
    color: "transparent"

    visible: Root.GlobalStates.sidebarRightOpen

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "sidebar"

    // Get title based on current view
    property string viewTitle: {
        switch (Root.GlobalStates.sidebarRightView) {
            case "network": return "[ Network ]"
            case "bluetooth": return "[ Bluetooth ]"
            case "audio": return "[ Audio ]"
            case "calendar": return "[ Calendar ]"
            case "notifications": return "[ Notifications ]"
            case "power": return "[ Power ]"
            case "weather": return "[ Weather ]"
            default: return "[ Settings ]"
        }
    }

    // Get keyboard hints based on current view
    property var viewHints: {
        switch (Root.GlobalStates.sidebarRightView) {
            case "network":
                return [
                    { key: "Esc", action: "close" },
                    { key: "j/k", action: "navigate" },
                    { key: "Enter", action: "connect" }
                ]
            case "bluetooth":
                return [
                    { key: "Esc", action: "close" },
                    { key: "j/k", action: "navigate" },
                    { key: "Enter", action: "pair" }
                ]
            case "audio":
                return [
                    { key: "Esc", action: "close" },
                    { key: "m", action: "mute" },
                    { key: "+/-", action: "volume" }
                ]
            case "notifications":
                return [
                    { key: "Esc", action: "close" },
                    { key: "d", action: "dismiss" },
                    { key: "D", action: "clear all" }
                ]
            case "power":
                return [
                    { key: "Esc", action: "close" },
                    { key: "s", action: "suspend" },
                    { key: "r", action: "reboot" },
                    { key: "p", action: "poweroff" }
                ]
            default:
                return [{ key: "Esc", action: "close" }]
        }
    }

    // TUI Panel container
    Common.TuiPanel {
        anchors.fill: parent
        title: root.viewTitle
        keyHints: root.viewHints

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
