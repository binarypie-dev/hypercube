import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "hud"

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

        // Active view: "default", "calendar", "notifications", "bluetooth", "help"
        property string activeView: "default"

        // Focus state: "input" or "notifications"
        property string focusState: "input"

        // DateTime
        property string currentTime: ""
        property string currentDate: ""

        // Weather
        property string weatherTemp: ""
        property string weatherIcon: ""
        property string weatherDesc: ""

        // View control functions
        function showCalendar() {
            activeView = "calendar";
            calendarView.reset();
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

        function showBluetooth() {
            activeView = "bluetooth";
        }

        function hideBluetooth() {
            activeView = "default";
        }

        function showHelp() {
            activeView = "help";
        }

        function hideHelp() {
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
            if (c === "/b" || c === "/bluetooth") {
                showBluetooth();
                return true;
            }
            if (c === "/?" || c === "/help") {
                showHelp();
                return true;
            }
            return false;
        }

        // DateTime update timer
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
            onClicked: (mouse) => {
                // Calculate hudContainer bounds
                var containerLeft = hudContainer.x;
                var containerRight = hudContainer.x + hudContainer.width;
                var containerTop = hudContainer.y;
                var containerBottom = hudContainer.y + hudContainer.height;

                // Only close if click is outside the container
                if (mouse.x < containerLeft || mouse.x > containerRight ||
                    mouse.y < containerTop || mouse.y > containerBottom) {
                    hud.hide();
                }
            }
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

                // Status bar
                StatusBar {
                    activeView: hud.activeView
                    notificationCount: hudScope.notificationList.length
                    currentDate: hud.currentDate
                    currentTime: hud.currentTime
                    weatherTemp: hud.weatherTemp
                    weatherIcon: hud.weatherIcon

                    onToggleNotifications: {
                        if (hud.activeView === "notifications") {
                            hud.hideNotifications();
                        } else {
                            hud.showNotifications();
                        }
                    }

                    onToggleCalendar: {
                        if (hud.activeView === "calendar") {
                            hud.hideCalendar();
                        } else {
                            hud.showCalendar();
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
                                    // Switch to default view to show app list
                                    hud.activeView = "default";
                                    hud.updateFilteredApps();
                                } else {
                                    hud.filteredApps = [];
                                }
                                appListView.currentIndex = 0;
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
                                    hud.launchApp(hud.filteredApps[appListView.currentIndex >= 0 ? appListView.currentIndex : 0]);
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
                                    // Ctrl+B for bluetooth
                                    else if (event.key === Qt.Key_B) {
                                        hud.showBluetooth();
                                        event.accepted = true;
                                    }
                                    // Ctrl+J to move focus to notification list
                                    else if (event.key === Qt.Key_J && hud.activeView === "notifications" && hudScope.notificationList.length > 0) {
                                        hud.focusState = "notifications";
                                        notificationsView.focusList();
                                        event.accepted = true;
                                    }
                                }
                            }
                            Keys.onDownPressed: appListView.moveDown()
                            Keys.onUpPressed: appListView.moveUp()

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

                // App list view
                AppList {
                    id: appListView
                    filteredApps: hud.filteredApps
                    isVisible: hud.activeView === "default" && hud.searchText && !hud.searchText.startsWith("/")

                    onAppLaunched: (app) => hud.launchApp(app)
                }

                // Calendar view
                CalendarView {
                    id: calendarView
                    isVisible: hud.activeView === "calendar"
                }

                // Notifications view
                NotificationsView {
                    id: notificationsView
                    isVisible: hud.activeView === "notifications"
                    notificationList: hudScope.notificationList

                    onDismissNotification: (notification) => hudScope.dismissNotification(notification)
                    onClearAllNotifications: hudScope.clearAllNotifications()
                    onRequestFocusInput: {
                        hud.focusState = "input";
                        searchInput.forceActiveFocus();
                    }
                }

                // Bluetooth view
                BluetoothView {
                    id: bluetoothView
                    isVisible: hud.activeView === "bluetooth"
                }

                // Help view
                HelpView {
                    id: helpView
                    isVisible: hud.activeView === "help"
                }
            }
        }
    }
}
