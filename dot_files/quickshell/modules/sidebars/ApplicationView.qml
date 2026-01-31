import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

import "../common" as Common
import "../../" as Root
import "../../services" as Services

// TUI-style application launcher
ColumnLayout {
    id: root
    spacing: 0
    anchors.topMargin: 5
    anchors.bottomMargin: 5

    property var searchResults: []
    property var allApps: []
    property string currentQuery: ""
    property bool isSearching: false

    property string allAppsQueryId: ""
    property string searchQueryId: ""
    property int retryCount: 0
    property int maxRetries: 5

    Component.onCompleted: {
        loadAllApps()
    }

    function loadAllApps() {
        allAppsQueryId = Services.Datacube.queryAll("", 500)
    }

    // Search bar
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        color: "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Common.Appearance.spacing.medium
            anchors.rightMargin: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.small

            // Chevron prompt
            Text {
                text: ">"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.normal
                font.bold: true
                color: Common.Appearance.colors.green
            }

            // Search input
            Common.TuiInput {
                id: searchInput
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                placeholderText: "Search applications..."

                onTextChanged: {
                    root.currentQuery = text
                    root.isSearching = text.trim() !== ""
                    if (root.isSearching) {
                        queryDebounceTimer.restart()
                    } else {
                        searchResults = []
                    }
                }

                onAccepted: {
                    if (appListView.currentIndex >= 0 && appListView.currentIndex < appListView.count) {
                        const apps = root.isSearching ? searchResults : allApps
                        launchApp(apps[appListView.currentIndex])
                    }
                }

                Keys.onEscapePressed: {
                    if (text !== "") {
                        text = ""
                    } else {
                        Root.GlobalStates.sidebarLeftOpen = false
                    }
                }

                Keys.onDownPressed: appListView.incrementCurrentIndex()
                Keys.onUpPressed: appListView.decrementCurrentIndex()

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_J && (event.modifiers & Qt.ControlModifier)) {
                        appListView.incrementCurrentIndex()
                        event.accepted = true
                    } else if (event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier)) {
                        appListView.decrementCurrentIndex()
                        event.accepted = true
                    }
                }
            }

            // Results count
            Text {
                text: appListView.count > 0
                    ? String(appListView.currentIndex + 1).padStart(3, ' ') + "/" + String(appListView.count).padEnd(3, ' ')
                    : "  0/0  "
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.colors.comment
            }
        }
    }

    // App list
    ListView {
        id: appListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: Common.Appearance.spacing.medium
        clip: true
        spacing: 4

        model: root.isSearching ? searchResults : allApps

        delegate: Rectangle {
            id: appDelegate
            required property var modelData
            required property int index

            width: appListView.width - 8
            height: 40

            property bool isSelected: appListView.currentIndex === index

            color: delegateMouseArea.containsMouse ? Common.Appearance.colors.bgHighlight : "transparent"
            border.width: isSelected ? 1 : 0
            border.color: Qt.alpha(Common.Appearance.colors.green, 0.6)
            radius: Common.Appearance.rounding.tiny

            RowLayout {
                anchors.fill: parent
                anchors.margins: Common.Appearance.spacing.small
                spacing: Common.Appearance.spacing.medium

                // App icon
                Item {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20

                    Image {
                        id: appIcon
                        anchors.fill: parent
                        source: modelData.icon || ""
                        sourceSize: Qt.size(20, 20)
                        smooth: true
                        visible: status === Image.Ready
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: appIcon.status !== Image.Ready
                        radius: Common.Appearance.rounding.tiny
                        color: Common.Appearance.colors.bgVisual

                        Text {
                            anchors.centerIn: parent
                            text: modelData.name ? modelData.name.charAt(0).toUpperCase() : "?"
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: 10
                            font.bold: true
                            color: Common.Appearance.colors.cyan
                        }
                    }
                }

                // App name and description
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: modelData.name || "Unknown"
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.normal
                        color: Common.Appearance.colors.fg
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: modelData.genericName && modelData.genericName !== modelData.name
                        Layout.fillWidth: true
                        text: modelData.genericName || ""
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.colors.comment
                        elide: Text.ElideRight
                    }
                }
            }

            MouseArea {
                id: delegateMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: launchApp(modelData)
            }
        }

        // Empty state
        Text {
            anchors.centerIn: parent
            visible: appListView.count === 0
            text: root.isSearching ? "-- No matches --" : "-- Loading... --"
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.small
            color: Common.Appearance.colors.comment
        }

        ScrollBar.vertical: ScrollBar {
            id: listScrollBar
            policy: ScrollBar.AsNeeded
            visible: listScrollBar.size < 1.0
            width: 8

            background: Rectangle {
                implicitWidth: 8
                color: Common.Appearance.colors.bgDark
                visible: listScrollBar.size < 1.0
            }

            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.alpha(Common.Appearance.colors.green, 0.6) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }
    }

    // Datacube query handling
    Connections {
        target: Services.Datacube

        function onQueryCompleted(queryId, results) {
            if (queryId === root.allAppsQueryId) {
                root.retryCount = 0
                root.allApps = results
            } else if (queryId === root.searchQueryId) {
                root.searchResults = results
            }
        }

        function onQueryFailed(queryId, error) {
            console.log("Datacube query failed:", queryId, error)
            if (queryId === root.allAppsQueryId && root.retryCount < root.maxRetries) {
                root.retryCount++
                console.log("Datacube: retrying allApps query (attempt", root.retryCount, "of", root.maxRetries, ")")
                retryTimer.start()
            }
        }
    }

    Timer {
        id: retryTimer
        interval: 1000 * root.retryCount
        repeat: false
        onTriggered: {
            root.loadAllApps()
        }
    }

    Timer {
        id: queryDebounceTimer
        interval: 150
        onTriggered: {
            const query = root.currentQuery
            if (!query || query.trim() === "") {
                searchResults = []
                root.searchQueryId = ""
                return
            }
            if (root.searchQueryId) {
                Services.Datacube.cancelQuery(root.searchQueryId)
            }
            root.searchQueryId = Services.Datacube.queryAll(query, 50)
        }
    }

    function launchApp(app) {
        const metadata = app?._raw?.metadata || {}
        const desktopId = metadata.desktop_id || app?.id || ""
        if (!desktopId) return

        const isTerminal = metadata.terminal === true || metadata.terminal === "true"
        const source = app?.source || "native"

        if (isTerminal) {
            appLaunchProcess.command = ["ghostty", "-e", desktopId]
        } else if (source === "flatpak") {
            appLaunchProcess.command = ["flatpak", "run", desktopId]
        } else {
            appLaunchProcess.command = ["gtk4-launch", desktopId]
        }
        appLaunchProcess.startDetached()

        Root.GlobalStates.sidebarLeftOpen = false
        searchInput.text = ""
    }

    Process {
        id: appLaunchProcess
        command: ["true"]
    }

    Connections {
        target: Root.GlobalStates
        function onSidebarLeftOpenChanged() {
            if (Root.GlobalStates.sidebarLeftOpen) {
                if (root.allApps.length === 0) {
                    root.retryCount = 0
                    root.loadAllApps()
                }
            } else {
                searchInput.text = ""
                searchResults = []
            }
        }
    }

    function focusSearch() {
        searchInput.focusInput()
        appListView.currentIndex = 0
    }
}
