import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

ShellRoot {
    id: root

    // Global launcher visibility state
    property bool launcherVisible: false

    function toggleLauncher() {
        launcherVisible = !launcherVisible;
    }

    // Handle IPC messages for launcher
    IpcHandler {
        target: "launcher"

        function toggle() {
            root.toggleLauncher();
        }

        function show() {
            root.launcherVisible = true;
        }

        function hide() {
            root.launcherVisible = false;
        }
    }

    // Notification server - acts as the notification daemon
    NotificationServer {
        id: notificationServer

        onNotification: (notification) => {
            notifications.addNotification(notification);
        }
    }

    // Application Launcher (Variants-based, creates windows per screen)
    Launcher {
        showing: root.launcherVisible
        onClose: root.launcherVisible = false
    }

    // Notification display
    Notifications {
        id: notifications
    }

    // OSD for volume/brightness
    Osd {
        id: osd
    }
}
