import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

Rectangle {
    id: appListView
    width: parent.width
    height: visible ? Math.min(filteredApps.length * 52, 300) : 0
    color: "transparent"

    required property var filteredApps
    required property bool isVisible

    visible: isVisible && filteredApps.length > 0

    signal appLaunched(var app)

    property alias currentIndex: appList.currentIndex

    function moveUp() {
        if (appList.currentIndex > 0) {
            appList.currentIndex--;
        }
    }

    function moveDown() {
        if (appList.currentIndex < filteredApps.length - 1) {
            appList.currentIndex++;
        }
    }

    function launchCurrent() {
        if (filteredApps.length > 0 && appList.currentIndex >= 0) {
            appLaunched(filteredApps[appList.currentIndex]);
        }
    }

    ListView {
        id: appList
        anchors.fill: parent
        clip: true
        spacing: 4
        currentIndex: 0

        model: appListView.filteredApps

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
                onClicked: appListView.appLaunched(modelData)
            }
        }

        ScrollBar.vertical: ScrollBar {
            active: true
            policy: ScrollBar.AsNeeded
        }
    }
}
