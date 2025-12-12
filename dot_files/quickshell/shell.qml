//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

ShellRoot {
    id: root

    // Global HUD visibility state
    property bool hudVisible: false

    // Notification storage
    property var notificationList: []

    // Notification server
    NotificationServer {
        id: notificationServer
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: (notification) => {
            // Must set tracked = true to retain the notification object
            notification.tracked = true;
            root.addNotification(notification);
        }
    }

    function toggleHud() {
        hudVisible = !hudVisible;
    }

    function addNotification(notification) {
        notificationList = [notification].concat(notificationList);
    }

    function dismissNotification(notification) {
        if (notification) {
            // Setting tracked = false dismisses and destroys the notification
            notification.tracked = false;
        }
        notificationList = notificationList.filter(n => n !== notification);
    }

    function clearAllNotifications() {
        for (var i = 0; i < notificationList.length; i++) {
            var n = notificationList[i];
            if (n) {
                n.tracked = false;
            }
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
