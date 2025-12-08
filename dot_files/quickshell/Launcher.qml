import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

Variants {
    id: launcherVariants

    property bool showing: false
    signal close()

    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: launcher

            required property var modelData
            screen: modelData

            visible: launcherVariants.showing

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

            // Desktop entries model
            DesktopEntries {
                id: desktopEntries
            }

            function updateFilteredApps() {
                var apps = [];
                var search = searchText.toLowerCase();

                for (var i = 0; i < desktopEntries.applications.values.length; i++) {
                    var app = desktopEntries.applications.values[i];
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
                launcherVariants.close();
            }

            function launchApp(app) {
                app.launch();
                hide();
            }

            onVisibleChanged: {
                if (visible) {
                    searchText = "";
                    searchInput.text = "";
                    updateFilteredApps();
                    searchInput.forceActiveFocus();
                }
            }

            Component.onCompleted: {
                updateFilteredApps();
            }

            // Background overlay
            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.7

                MouseArea {
                    anchors.fill: parent
                    onClicked: launcher.hide()
                }
            }

            // Main launcher container
            Rectangle {
                id: launcherContainer
                anchors.centerIn: parent
                width: 600
                height: 500
                radius: 12
                color: "#1a1b26"
                border.color: "#33467c"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Search input
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: 8
                        color: "#24283b"
                        border.color: searchInput.activeFocus ? "#7aa2f7" : "#33467c"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Text {
                                text: ""
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                color: "#565f89"
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 16
                                color: "#c0caf5"
                                selectionColor: "#33467c"
                                selectedTextColor: "#c0caf5"

                                onTextChanged: {
                                    launcher.searchText = text;
                                    launcher.updateFilteredApps();
                                }

                                Keys.onEscapePressed: launcher.hide()
                                Keys.onReturnPressed: {
                                    if (launcher.filteredApps.length > 0) {
                                        launcher.launchApp(launcher.filteredApps[appList.currentIndex >= 0 ? appList.currentIndex : 0]);
                                    }
                                }
                                Keys.onDownPressed: {
                                    if (appList.currentIndex < launcher.filteredApps.length - 1) {
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
                                    text: "Search applications..."
                                    font: parent.font
                                    color: "#565f89"
                                    visible: !parent.text
                                }
                            }
                        }
                    }

                    // App list
                    ListView {
                        id: appList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        currentIndex: 0

                        model: launcher.filteredApps

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
                                        font.family: "JetBrainsMono Nerd Font"
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
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 14
                                        color: "#c0caf5"
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.genericName || ""
                                        font.family: "JetBrainsMono Nerd Font"
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
                                onClicked: launcher.launchApp(modelData)
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            active: true
                            policy: ScrollBar.AsNeeded
                        }
                    }
                }
            }

            // Global keyboard handling
            Item {
                focus: launcher.visible
                Keys.onEscapePressed: launcher.hide()
            }
        }
    }
}
