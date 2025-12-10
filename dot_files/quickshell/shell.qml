import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    // Global HUD visibility state
    property bool hudVisible: false

    // Notification storage (disabled for now)
    property var notificationList: []

    function toggleHud() {
        hudVisible = !hudVisible;
    }

    function addNotification(notification) {
        notificationList = [notification].concat(notificationList);
    }

    function dismissNotification(notification) {
        notification.dismiss();
        notificationList = notificationList.filter(n => n !== notification);
    }

    function clearAllNotifications() {
        for (var i = 0; i < notificationList.length; i++) {
            notificationList[i].dismiss();
        }
        notificationList = [];
    }

    // Handle IPC messages for HUD
    IpcHandler {
        target: "hud"

        function toggle() {
            root.toggleHud();
        }

        function show() {
            root.hudVisible = true;
        }

        function hide() {
            root.hudVisible = false;
        }
    }

    // Keep launcher target for backwards compatibility
    IpcHandler {
        target: "launcher"

        function toggle() {
            root.toggleHud();
        }

        function show() {
            root.hudVisible = true;
        }

        function hide() {
            root.hudVisible = false;
        }
    }

    // Command HUD
    Hud {
        showing: root.hudVisible
        onClose: root.hudVisible = false
        notificationList: root.notificationList
        onDismissNotification: (notification) => root.dismissNotification(notification)
        onClearAllNotifications: root.clearAllNotifications()
    }

    // OSD for volume/brightness
    Osd {
        id: osd
    }
}
