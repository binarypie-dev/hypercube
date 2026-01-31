import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

import "../common" as Common
import "../../" as Root
import "../../services" as Services

// Vim-style application launcher with TUI aesthetics
ColumnLayout {
    id: root
    anchors.fill: parent
    anchors.margins: 0
    spacing: 0

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

    // Command line search (vim-style at top)
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 28
        Layout.alignment: Qt.AlignTop
        color: Common.Appearance.colors.bgDark

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Common.Appearance.spacing.small
            anchors.rightMargin: Common.Appearance.spacing.small
            spacing: 0

            // Command prompt indicator
            Text {
                text: root.isSearching ? "/" : ":"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                font.bold: true
                color: Common.Appearance.colors.cyan
            }

            // Search input
            TextInput {
                id: searchInput
                Layout.fillWidth: true
                Layout.leftMargin: Common.Appearance.spacing.tiny
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.colors.fg
                clip: true
                selectByMouse: true
                selectionColor: Common.Appearance.colors.bgVisual
                selectedTextColor: Common.Appearance.colors.fg

                property string placeholderText: "Type to search..."

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: searchInput.placeholderText
                    font: searchInput.font
                    color: Common.Appearance.colors.comment
                    visible: !searchInput.text && !searchInput.activeFocus
                }

                onTextChanged: {
                    root.currentQuery = text
                    root.isSearching = text.trim() !== ""
                    if (root.isSearching) {
                        queryDebounceTimer.restart()
                    } else {
                        searchResults = []
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
                Keys.onReturnPressed: {
                    if (appListView.currentIndex >= 0 && appListView.currentIndex < appListView.count) {
                        const apps = root.isSearching ? searchResults : allApps
                        launchApp(apps[appListView.currentIndex])
                    }
                }

                // Ctrl+J/K navigation
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

            // Results count (vim-style)
            Text {
                visible: appListView.count > 0
                text: "[" + (appListView.currentIndex + 1) + "/" + appListView.count + "]"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.tiny
                color: Common.Appearance.colors.comment
            }
        }

        // Cursor blink simulation
        Rectangle {
            visible: searchInput.activeFocus && searchInput.cursorVisible
            x: searchInput.x + searchInput.cursorRectangle.x + Common.Appearance.spacing.small + 8
            y: (parent.height - height) / 2
            width: 2
            height: Common.Appearance.fontSize.small
            color: Common.Appearance.colors.fg
        }
    }

    // Separator line
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Common.Appearance.colors.border
    }

    // App list (vim-style)
    ListView {
        id: appListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 0

        model: root.isSearching ? searchResults : allApps

        // Line numbers like vim
        property int lineNumberWidth: 36

        delegate: MouseArea {
            id: appDelegate
            required property var modelData
            required property int index

            width: appListView.width
            height: 28
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: launchApp(modelData)

            property bool isSelected: appListView.currentIndex === index

            // Selection highlight (vim-style visual line)
            Rectangle {
                anchors.fill: parent
                color: appDelegate.isSelected
                    ? Common.Appearance.colors.bgVisual
                    : (appDelegate.containsMouse
                        ? Common.Appearance.colors.bgHighlight
                        : "transparent")
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // Line number (vim-style gutter)
                Rectangle {
                    Layout.preferredWidth: appListView.lineNumberWidth
                    Layout.fillHeight: true
                    color: Common.Appearance.colors.bgDark

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: Common.Appearance.spacing.small
                        anchors.verticalCenter: parent.verticalCenter
                        text: (index + 1).toString()
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.tiny
                        color: appDelegate.isSelected
                            ? Common.Appearance.colors.yellow
                            : Common.Appearance.colors.comment
                    }
                }

                // Separator line
                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: Common.Appearance.colors.fgGutter
                }

                // App icon
                Item {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    Layout.leftMargin: Common.Appearance.spacing.small

                    property string iconSource: modelData.icon || ""

                    Image {
                        id: appIcon
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        source: parent.iconSource
                        sourceSize: Qt.size(18, 18)
                        smooth: true
                        visible: status === Image.Ready
                    }

                    // Fallback: colored letter
                    Rectangle {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        visible: appIcon.status !== Image.Ready
                        radius: Common.Appearance.rounding.tiny
                        color: Common.Appearance.colors.bgVisual

                        Text {
                            anchors.centerIn: parent
                            text: modelData.name ? modelData.name.charAt(0).toUpperCase() : "?"
                            font.pixelSize: 10
                            font.bold: true
                            color: Common.Appearance.colors.cyan
                        }
                    }
                }

                // App name
                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: Common.Appearance.spacing.small
                    text: modelData.name || "Unknown"
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: appDelegate.isSelected
                        ? Common.Appearance.colors.fg
                        : Common.Appearance.colors.fgDark
                    elide: Text.ElideRight
                }

                // Category/description (dimmed)
                Text {
                    Layout.rightMargin: Common.Appearance.spacing.medium
                    visible: modelData.genericName && modelData.genericName !== modelData.name
                    text: modelData.genericName || ""
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.tiny
                    color: Common.Appearance.colors.comment
                    elide: Text.ElideRight
                }
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
            policy: ScrollBar.AsNeeded
            width: 8

            contentItem: Rectangle {
                implicitWidth: 6
                radius: 3
                color: Common.Appearance.colors.bgVisual
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
        searchInput.forceActiveFocus()
        appListView.currentIndex = 0
    }
}
