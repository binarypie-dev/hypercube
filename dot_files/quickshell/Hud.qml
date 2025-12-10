import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: hudScope

    property bool showing: false
    property var notificationList: []
    signal close()
    signal dismissNotification(var notification)
    signal clearAllNotifications()

    // Weather settings - empty string = auto-detect by IP
    property string weatherLocation: ""

    PanelWindow {
        id: hud

        visible: hudScope.showing

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        color: "transparent"

        // Search state
        property string searchText: ""
        property var filteredApps: []

        // Active view: "default", "calendar", "notifications"
        property string activeView: "default"

        // Focus state: "input" or "notifications"
        property string focusState: "input"

        // DateTime
        property string currentTime: ""
        property string currentDate: ""

        // Calendar state
        property int calendarMonth: new Date().getMonth()
        property int calendarYear: new Date().getFullYear()

        // Weather
        property string weatherTemp: ""
        property string weatherIcon: ""
        property string weatherDesc: ""

        function showCalendar() {
            activeView = "calendar";
            var now = new Date();
            calendarMonth = now.getMonth();
            calendarYear = now.getFullYear();
        }

        function hideCalendar() {
            activeView = "default";
        }

        function showNotifications() {
            activeView = "notifications";
        }

        function hideNotifications() {
            activeView = "default";
        }

        function handleCommand(cmd) {
            var c = cmd.toLowerCase().trim();
            if (c === "/c" || c === "/calendar") {
                showCalendar();
                return true;
            }
            if (c === "/n" || c === "/notifications") {
                showNotifications();
                return true;
            }
            return false;
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                var now = new Date();
                hud.currentTime = now.toLocaleTimeString(Qt.locale(), "h:mm ap");
                hud.currentDate = now.toLocaleDateString(Qt.locale(), "dddd, MMMM d");
            }
        }

        // Weather fetch - runs every 15 minutes
        Timer {
            interval: 900000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: weatherProcess.running = true
        }

        Process {
            id: weatherProcess
            command: ["curl", "-sf", "wttr.in/" + hudScope.weatherLocation + "?format=%t|%C"]
            stdout: SplitParser {
                onRead: (line) => {
                    var parts = line.split("|");
                    if (parts.length >= 2) {
                        hud.weatherTemp = parts[0].trim();
                        hud.weatherDesc = parts[1].trim();
                        // Map conditions to icons
                        var desc = hud.weatherDesc.toLowerCase();
                        if (desc.includes("sun") || desc.includes("clear")) {
                            hud.weatherIcon = "";
                        } else if (desc.includes("cloud") || desc.includes("overcast")) {
                            hud.weatherIcon = "";
                        } else if (desc.includes("rain") || desc.includes("drizzle")) {
                            hud.weatherIcon = "";
                        } else if (desc.includes("snow")) {
                            hud.weatherIcon = "";
                        } else if (desc.includes("thunder") || desc.includes("storm")) {
                            hud.weatherIcon = "";
                        } else if (desc.includes("fog") || desc.includes("mist")) {
                            hud.weatherIcon = "";
                        } else if (desc.includes("partly")) {
                            hud.weatherIcon = "";
                        } else {
                            hud.weatherIcon = "";
                        }
                    }
                }
            }
        }

        function updateFilteredApps() {
            var apps = [];
            var search = searchText.toLowerCase();

            for (var i = 0; i < DesktopEntries.applications.values.length; i++) {
                var app = DesktopEntries.applications.values[i];
                if (!app.noDisplay && (
                    app.name.toLowerCase().includes(search) ||
                    (app.genericName && app.genericName.toLowerCase().includes(search)) ||
                    (app.comment && app.comment.toLowerCase().includes(search)))) {
                    apps.push(app);
                }
            }

            // Sort alphabetically
            apps.sort(function(a, b) {
                return a.name.localeCompare(b.name);
            });

            filteredApps = apps.slice(0, 50); // Limit results
        }

        function hide() {
            searchText = "";
            searchInput.text = "";
            activeView = "default";
            focusState = "input";
            hudScope.close();
        }

        function launchApp(app) {
            app.execute();
            hide();
        }

        onVisibleChanged: {
            if (visible) {
                searchText = "";
                searchInput.text = "";
                filteredApps = [];
                activeView = "default";
                focusState = "input";
                focusTimer.start();
            }
        }

        Timer {
            id: focusTimer
            interval: 50
            onTriggered: searchInput.forceActiveFocus()
        }

        // Click outside to close
        MouseArea {
            anchors.fill: parent
            onClicked: hud.hide()
        }

        // Main HUD container
        Rectangle {
            id: hudContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.15
            width: 700
            height: contentColumn.implicitHeight + 16
            radius: 12
            color: "#1a1b26"
            border.color: "#33467c"
            border.width: 1

            Behavior on height {
                NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
            }

            Column {
                id: contentColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                spacing: 8

                // Status bar: Notifications | Date | Weather | Time
                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 8
                    color: "#24283b"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // Notification icon
                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 6
                            color: notifMouseArea.containsMouse ? "#33467c" : (hud.activeView === "notifications" ? "#33467c" : "transparent")

                            Text {
                                anchors.centerIn: parent
                                text: "󰂚"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 16
                                color: hudScope.notificationList.length > 0 ? "#ff9e64" : "#7aa2f7"
                            }

                            MouseArea {
                                id: notifMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (hud.activeView === "notifications") {
                                        hud.hideNotifications();
                                    } else {
                                        hud.showNotifications();
                                    }
                                }
                            }
                        }

                        // Separator
                        Text {
                            text: "|"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                            color: "#33467c"
                        }

                        // Date/Time clickable area
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            radius: 6
                            color: dateTimeMouseArea.containsMouse ? "#33467c" : "transparent"

                            MouseArea {
                                id: dateTimeMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (hud.activeView === "calendar") {
                                        hud.hideCalendar();
                                    } else {
                                        hud.showCalendar();
                                    }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 12

                                // Date
                                Text {
                                    text: hud.currentDate
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 14
                                    color: "#c0caf5"
                                }

                                Item { Layout.fillWidth: true }

                                // Weather
                                Row {
                                    spacing: 6
                                    visible: hud.weatherTemp !== ""

                                    Text {
                                        text: hud.weatherIcon
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 14
                                        color: "#7aa2f7"
                                    }

                                    Text {
                                        text: hud.weatherTemp
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 14
                                        color: "#c0caf5"
                                    }
                                }

                                // Separator
                                Text {
                                    text: "|"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 14
                                    color: "#33467c"
                                    visible: hud.weatherTemp !== ""
                                }

                                // Time
                                Text {
                                    text: hud.currentTime
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 14
                                    color: "#c0caf5"
                                }
                            }
                        }
                    }
                }

                // Command input
                Rectangle {
                    id: searchBox
                    width: parent.width
                    height: 48
                    radius: 8
                    color: "#24283b"
                    border.color: searchInput.activeFocus ? "#7aa2f7" : "#33467c"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text {
                            text: ">"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 18
                            color: "#7aa2f7"
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font.family: "JetBrains Mono"
                            font.pixelSize: 16
                            color: "#c0caf5"
                            selectionColor: "#33467c"
                            selectedTextColor: "#c0caf5"

                            onTextChanged: {
                                hud.searchText = text;
                                if (text && !text.startsWith("/")) {
                                    hud.updateFilteredApps();
                                } else {
                                    hud.filteredApps = [];
                                }
                                appList.currentIndex = 0;
                            }

                            Keys.onEscapePressed: {
                                if (text !== "") {
                                    text = "";
                                } else {
                                    hud.hide();
                                }
                            }
                            Keys.onReturnPressed: {
                                // Check for commands first
                                if (hud.handleCommand(text)) {
                                    return;
                                }
                                if (hud.filteredApps.length > 0) {
                                    hud.launchApp(hud.filteredApps[appList.currentIndex >= 0 ? appList.currentIndex : 0]);
                                }
                            }
                            Keys.onPressed: (event) => {
                                if (event.modifiers & Qt.ControlModifier) {
                                    // Ctrl+C for calendar
                                    if (event.key === Qt.Key_C) {
                                        hud.showCalendar();
                                        event.accepted = true;
                                    }
                                    // Ctrl+N for notifications
                                    else if (event.key === Qt.Key_N) {
                                        hud.showNotifications();
                                        event.accepted = true;
                                    }
                                    // Ctrl+J to move focus to notification list
                                    else if (event.key === Qt.Key_J && hud.activeView === "notifications" && hudScope.notificationList.length > 0) {
                                        hud.focusState = "notifications";
                                        notificationList.currentIndex = 0;
                                        notificationList.forceActiveFocus();
                                        event.accepted = true;
                                    }
                                }
                            }
                            Keys.onDownPressed: {
                                if (appList.currentIndex < hud.filteredApps.length - 1) {
                                    appList.currentIndex++;
                                }
                            }
                            Keys.onUpPressed: {
                                if (appList.currentIndex > 0) {
                                    appList.currentIndex--;
                                }
                            }

                            Text {
                                anchors.fill: parent
                                text: "Enter command..."
                                font: parent.font
                                color: "#565f89"
                                visible: !parent.text
                            }
                        }
                    }
                }

                // App list container (shows when typing non-command text)
                Rectangle {
                    id: appListContainer
                    width: parent.width
                    height: visible ? Math.min(hud.filteredApps.length * 52, 300) : 0
                    visible: hud.activeView === "default" && hud.searchText && !hud.searchText.startsWith("/") && hud.filteredApps.length > 0
                    color: "transparent"

                    ListView {
                        id: appList
                        anchors.fill: parent
                        clip: true
                        spacing: 4
                        currentIndex: 0

                        model: hud.filteredApps

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: appList.width
                            height: 48
                            radius: 6
                            color: mouseArea.containsMouse || appList.currentIndex === index ? "#33467c" : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 12

                                // App icon
                                Image {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    source: modelData.icon ? "image://icon/" + modelData.icon : ""
                                    sourceSize: Qt.size(32, 32)

                                    Text {
                                        anchors.centerIn: parent
                                        text: ""
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 20
                                        color: "#7aa2f7"
                                        visible: parent.status !== Image.Ready
                                    }
                                }

                                // App name and description
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 14
                                        color: "#c0caf5"
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.genericName || ""
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 11
                                        color: "#565f89"
                                        elide: Text.ElideRight
                                        visible: text !== ""
                                    }
                                }
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: hud.launchApp(modelData)
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            active: true
                            policy: ScrollBar.AsNeeded
                        }
                    }
                }

                // Calendar view
                Rectangle {
                    id: calendarContainer
                    width: parent.width
                    height: visible ? calendarContent.implicitHeight : 0
                    visible: hud.activeView === "calendar"
                    color: "transparent"
                    clip: true

                    Behavior on height {
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                    }

                    Column {
                        id: calendarContent
                        width: parent.width
                        spacing: 8

                        // Month/Year header with navigation
                        Rectangle {
                            width: parent.width
                            height: 36
                            radius: 6
                            color: "#24283b"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8

                                // Previous month
                                Rectangle {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: 4
                                    color: prevMonthMouse.containsMouse ? "#33467c" : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "<"
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "#c0caf5"
                                    }

                                    MouseArea {
                                        id: prevMonthMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (hud.calendarMonth === 0) {
                                                hud.calendarMonth = 11;
                                                hud.calendarYear--;
                                            } else {
                                                hud.calendarMonth--;
                                            }
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                // Month Year display
                                Text {
                                    text: new Date(hud.calendarYear, hud.calendarMonth, 1).toLocaleDateString(Qt.locale(), "MMMM yyyy")
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#c0caf5"
                                }

                                Item { Layout.fillWidth: true }

                                // Next month
                                Rectangle {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: 4
                                    color: nextMonthMouse.containsMouse ? "#33467c" : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: ">"
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "#c0caf5"
                                    }

                                    MouseArea {
                                        id: nextMonthMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (hud.calendarMonth === 11) {
                                                hud.calendarMonth = 0;
                                                hud.calendarYear++;
                                            } else {
                                                hud.calendarMonth++;
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Day headers
                        Row {
                            width: parent.width

                            Repeater {
                                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                                delegate: Item {
                                    width: parent.width / 7
                                    height: 24

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 11
                                        color: "#565f89"
                                    }
                                }
                            }
                        }

                        // Calendar grid
                        Grid {
                            id: calendarGrid
                            width: parent.width
                            columns: 7

                            property var firstDay: new Date(hud.calendarYear, hud.calendarMonth, 1)
                            property int startDay: firstDay.getDay()
                            property int daysInMonth: new Date(hud.calendarYear, hud.calendarMonth + 1, 0).getDate()
                            property var today: new Date()

                            Repeater {
                                model: 42

                                delegate: Item {
                                    width: calendarGrid.width / 7
                                    height: 32

                                    property int dayNum: index - calendarGrid.startDay + 1
                                    property bool isCurrentMonth: dayNum > 0 && dayNum <= calendarGrid.daysInMonth
                                    property bool isToday: isCurrentMonth &&
                                        dayNum === calendarGrid.today.getDate() &&
                                        hud.calendarMonth === calendarGrid.today.getMonth() &&
                                        hud.calendarYear === calendarGrid.today.getFullYear()

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 28
                                        height: 28
                                        radius: 14
                                        color: isToday ? "#7aa2f7" : "transparent"
                                        visible: isCurrentMonth

                                        Text {
                                            anchors.centerIn: parent
                                            text: isCurrentMonth ? dayNum : ""
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: 12
                                            color: isToday ? "#1a1b26" : "#c0caf5"
                                        }
                                    }
                                }
                            }
                        }

                    }
                }

                // Notifications view
                Rectangle {
                    id: notificationsContainer
                    width: parent.width
                    height: visible ? Math.min(notificationsContent.implicitHeight, 350) : 0
                    visible: hud.activeView === "notifications"
                    color: "transparent"
                    clip: true

                    Behavior on height {
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
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
                            visible: hudScope.notificationList.length === 0

                            Text {
                                anchors.centerIn: parent
                                text: "No notifications"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 14
                                color: "#565f89"
                            }
                        }

                        // Clear all button
                        Rectangle {
                            width: parent.width
                            height: 28
                            radius: 6
                            color: clearAllMouse.containsMouse ? "#f7768e" : "#24283b"
                            visible: hudScope.notificationList.length > 0

                            Text {
                                anchors.centerIn: parent
                                text: " Clear All (" + hudScope.notificationList.length + ")"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 12
                                color: clearAllMouse.containsMouse ? "#1a1b26" : "#565f89"
                            }

                            MouseArea {
                                id: clearAllMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: hudScope.clearAllNotifications()
                            }
                        }

                        // Notification list
                        ListView {
                            id: notificationList
                            width: parent.width
                            height: Math.min(contentHeight, 300)
                            clip: true
                            spacing: 4
                            visible: hudScope.notificationList.length > 0

                            model: hudScope.notificationList

                            delegate: Rectangle {
                                required property var modelData
                                required property int index

                                width: notificationList.width
                                height: notifContent.implicitHeight + 16
                                radius: 6
                                color: notifMouse.containsMouse || notificationList.currentIndex === index ? "#33467c" : "#24283b"

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
                                                onClicked: hudScope.dismissNotification(modelData)
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
                                        notificationList.currentIndex = index;
                                    }
                                }
                            }

                            // Keyboard navigation
                            Keys.onUpPressed: {
                                if (currentIndex > 0) currentIndex--;
                            }
                            Keys.onDownPressed: {
                                if (currentIndex < count - 1) currentIndex++;
                            }
                            Keys.onPressed: (event) => {
                                // Vim bindings
                                if (event.key === Qt.Key_K) {
                                    if (currentIndex > 0) currentIndex--;
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_J) {
                                    if (currentIndex < count - 1) currentIndex++;
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_D || event.key === Qt.Key_X) {
                                    // Dismiss current
                                    if (currentIndex >= 0 && currentIndex < hudScope.notificationList.length) {
                                        hudScope.dismissNotification(hudScope.notificationList[currentIndex]);
                                    }
                                    event.accepted = true;
                                } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_K) {
                                    // Ctrl+K to go back to input
                                    hud.focusState = "input";
                                    searchInput.forceActiveFocus();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Escape) {
                                    hud.focusState = "input";
                                    searchInput.forceActiveFocus();
                                    event.accepted = true;
                                }
                            }

                            ScrollBar.vertical: ScrollBar {
                                active: true
                                policy: ScrollBar.AsNeeded
                            }
                        }
                    }
                }
            }
        }
    }
}
