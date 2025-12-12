import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: notificationsView
    width: parent.width
    height: visible ? Math.min(notificationsContent.implicitHeight, 350) : 0
    color: "transparent"
    clip: true

    required property bool isVisible
    required property var notificationList

    visible: isVisible

    signal dismissNotification(var notification)
    signal clearAllNotifications()
    signal requestFocusInput()

    property alias currentIndex: notificationListView.currentIndex
    property bool hasSelection: false
    property bool clearAllSelected: false
    property int lastSelectedIndex: 0

    Behavior on height {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
    }

    function focusList() {
        if (notificationList.length > 0) {
            hasSelection = true;
            clearAllSelected = false;
            // Restore last selected, clamped to valid range
            var idx = Math.min(lastSelectedIndex, notificationList.length - 1);
            notificationListView.currentIndex = idx;
            notificationListView.positionViewAtIndex(idx, ListView.Contain);
            notificationListView.forceActiveFocus();
        }
    }

    function selectAndScroll(newIndex) {
        if (newIndex >= 0 && newIndex < notificationListView.count) {
            hasSelection = true;
            clearAllSelected = false;
            lastSelectedIndex = newIndex;
            notificationListView.currentIndex = newIndex;
            notificationListView.positionViewAtIndex(newIndex, ListView.Contain);
        }
    }

    function selectClearAll() {
        hasSelection = false;
        clearAllSelected = true;
    }

    function moveUp() {
        if (clearAllSelected) {
            // Move from Clear All back to last notification
            clearAllSelected = false;
            hasSelection = true;
            notificationListView.currentIndex = notificationListView.count - 1;
            notificationListView.positionViewAtIndex(notificationListView.currentIndex, ListView.Contain);
        } else if (!hasSelection) {
            selectAndScroll(0);
        } else if (currentIndex > 0) {
            selectAndScroll(currentIndex - 1);
        }
    }

    function moveDown() {
        if (clearAllSelected) {
            // Already at bottom, do nothing
            return;
        } else if (!hasSelection) {
            selectAndScroll(0);
        } else if (currentIndex < notificationListView.count - 1) {
            selectAndScroll(currentIndex + 1);
        } else if (currentIndex === notificationListView.count - 1) {
            // At last notification, move to Clear All
            selectClearAll();
        }
    }

    function exitUp() {
        // Ctrl+K - exit up
        if (clearAllSelected) {
            // From Clear All, go to bottom of list
            clearAllSelected = false;
            hasSelection = true;
            notificationListView.currentIndex = notificationListView.count - 1;
            notificationListView.positionViewAtIndex(notificationListView.currentIndex, ListView.Contain);
        } else {
            // From list, go to text box
            hasSelection = false;
            clearAllSelected = false;
            requestFocusInput();
        }
    }

    function exitDown() {
        // Ctrl+J - exit to Clear All
        hasSelection = false;
        selectClearAll();
    }

    function dismissCurrentAndSelectNext() {
        if (!hasSelection || currentIndex < 0 || currentIndex >= notificationList.length) {
            return;
        }
        var dismissIdx = currentIndex;
        var nextIdx = dismissIdx;
        // If we're at the last item, select the previous one
        if (dismissIdx >= notificationList.length - 1) {
            nextIdx = Math.max(0, dismissIdx - 1);
        }
        lastSelectedIndex = nextIdx;
        var notif = notificationList[dismissIdx];
        dismissNotification(notif);
        // After dismiss, list will be one shorter - update current index
        // Use Qt.callLater to ensure list has updated first
        Qt.callLater(function() {
            if (notificationList.length > 0) {
                var clampedIdx = Math.min(nextIdx, notificationList.length - 1);
                notificationListView.currentIndex = clampedIdx;
                lastSelectedIndex = clampedIdx;
                notificationListView.positionViewAtIndex(clampedIdx, ListView.Contain);
            } else {
                hasSelection = false;
            }
        });
    }

    Column {
        id: notificationsContent
        width: parent.width
        spacing: 4

        // Empty state
        Rectangle {
            width: parent.width
            height: 60
            radius: 6
            color: "#24283b"
            visible: notificationsView.notificationList.length === 0

            Text {
                anchors.centerIn: parent
                text: "No notifications"
                font.family: "JetBrains Mono"
                font.pixelSize: 14
                color: "#565f89"
            }
        }

        // Notification list
        ListView {
            id: notificationListView
            width: parent.width
            height: Math.min(contentHeight, 300)
            clip: true
            spacing: 4
            visible: notificationsView.notificationList.length > 0
            highlightFollowsCurrentItem: false
            highlight: null

            model: notificationsView.notificationList

            delegate: Rectangle {
                required property var modelData
                required property int index

                width: notificationListView.width
                height: notifContent.implicitHeight + 16
                radius: 6
                color: notifMouse.containsMouse || (notificationsView.hasSelection && notificationListView.currentIndex === index) ? "#33467c" : "#24283b"

                Column {
                    id: notifContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8
                    spacing: 4

                    RowLayout {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: modelData.summary || modelData.appName || "Notification"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#c0caf5"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: ""
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                            color: dismissNotifMouse.containsMouse ? "#f7768e" : "#565f89"

                            MouseArea {
                                id: dismissNotifMouse
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: notificationsView.dismissNotification(modelData)
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: modelData.body || ""
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        color: "#565f89"
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }

                MouseArea {
                    id: notifMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    z: -1
                    onClicked: {
                        notificationsView.hasSelection = true;
                        notificationListView.currentIndex = index;
                    }
                }
            }

            // Keyboard navigation
            Keys.onUpPressed: notificationsView.moveUp()
            Keys.onDownPressed: notificationsView.moveDown()
            Keys.onReturnPressed: {
                if (notificationsView.clearAllSelected) {
                    notificationsView.clearAllNotifications();
                } else if (notificationsView.hasSelection && currentIndex >= 0 && currentIndex < notificationsView.notificationList.length) {
                    // Invoke default action (first action) on Enter
                    var notif = notificationsView.notificationList[currentIndex];
                    if (notif.actions && notif.actions.length > 0) {
                        notif.actions[0].invoke();
                        // If not resident, notification auto-dismisses, select next
                        if (!notif.resident) {
                            notificationsView.dismissCurrentAndSelectNext();
                        }
                    }
                }
            }
            Keys.onPressed: (event) => {
                if (event.modifiers & Qt.ControlModifier) {
                    // Ctrl+K - exit up to text box
                    if (event.key === Qt.Key_K) {
                        notificationsView.exitUp();
                        event.accepted = true;
                    }
                    // Ctrl+J - exit down to Clear All
                    else if (event.key === Qt.Key_J) {
                        notificationsView.exitDown();
                        event.accepted = true;
                    }
                } else {
                    // Vim bindings (no modifier)
                    if (event.key === Qt.Key_K) {
                        notificationsView.moveUp();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_J) {
                        notificationsView.moveDown();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_G && (event.modifiers & Qt.ShiftModifier)) {
                        // Shift+G - go to last notification
                        notificationsView.selectAndScroll(notificationListView.count - 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_G) {
                        // g - go to top
                        notificationsView.selectAndScroll(0);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_D || event.key === Qt.Key_X ||
                               event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
                        // Dismiss current and select next
                        notificationsView.dismissCurrentAndSelectNext();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        notificationsView.exitUp();
                        event.accepted = true;
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                active: true
                policy: ScrollBar.AsNeeded
            }
        }

        // Clear all button (at bottom)
        Rectangle {
            width: parent.width
            height: 28
            radius: 6
            color: clearAllMouse.containsMouse || notificationsView.clearAllSelected ? "#f7768e" : "#24283b"
            visible: notificationsView.notificationList.length > 0

            Text {
                anchors.centerIn: parent
                text: " Clear All (" + notificationsView.notificationList.length + ")"
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                color: clearAllMouse.containsMouse || notificationsView.clearAllSelected ? "#1a1b26" : "#565f89"
            }

            MouseArea {
                id: clearAllMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: notificationsView.clearAllNotifications()
            }
        }
    }
}
