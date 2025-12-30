pragma Singleton

import QtQuick
import Quickshell

// Notification manager service
// Works with the NotificationServer in shell.qml
Singleton {
    id: root

    property var notifications: []
    property int unreadCount: 0

    // Add a notification from the NotificationServer
    function addNotification(notification) {
        const hints = notification.hints || {}

        // Convert QML actions list to JS array with proper properties
        let actionsArray = []
        if (notification.actions) {
            for (let i = 0; i < notification.actions.length; i++) {
                const action = notification.actions[i]
                actionsArray.push({
                    identifier: action.identifier || "",
                    text: action.text || "Action",
                    _raw: action  // Keep reference for invoke()
                })
            }
        }

        const notif = {
            id: notification.id || Date.now(),
            appName: notification.appName || "Unknown",
            appIcon: notification.appIcon || "",
            summary: notification.summary || "",
            body: notification.body || "",
            image: notification.image || "",
            actions: actionsArray,
            hints: hints,
            time: new Date(),
            urgency: hints.urgency || 1,
            persistent: hints.resident || false,
            _raw: notification  // Keep reference to original for dismiss/expire
        }

        // Add to front
        notifications = [notif, ...notifications]
        unreadCount++

        // Emit signal for popup
        notificationAdded(notif)
    }

    // Remove a notification
    function removeNotification(id) {
        notifications = notifications.filter(n => n.id !== id)
        notificationRemoved(id)
    }

    // Clear all notifications
    function clearAll() {
        notifications = []
        unreadCount = 0
        notificationsCleared()
    }

    // Mark all as read
    function markAllRead() {
        unreadCount = 0
    }

    // Invoke an action on a notification
    function invokeAction(id, actionId) {
        const notif = notifications.find(n => n.id === id)
        if (notif) {
            // Find and invoke the raw action
            const action = notif.actions.find(a => a.identifier === actionId)
            if (action && action._raw && action._raw.invoke) {
                action._raw.invoke()
            }
            actionInvoked(id, actionId)
            if (!notif.persistent) {
                removeNotification(id)
            }
        }
    }

    // Signals
    signal notificationAdded(var notification)
    signal notificationRemoved(var id)
    signal notificationsCleared()
    signal actionInvoked(var id, string actionId)
}
