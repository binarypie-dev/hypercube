import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

import "../common" as Common
import "../../" as Root
import "../../services" as Services

// Application launcher view for the left sidebar
ColumnLayout {
    id: root
    spacing: Common.Appearance.spacing.medium

    // State for search results
    property var searchResults: []
    property var allApps: []
    property string currentQuery: ""
    property bool isSearching: false

    // Track the query we're waiting for results from
    property string allAppsQueryId: ""
    property string searchQueryId: ""
    property int retryCount: 0
    property int maxRetries: 5

    // Load all apps on startup
    Component.onCompleted: {
        loadAllApps()
    }

    function loadAllApps() {
        allAppsQueryId = Services.Datacube.queryAll("", 500)
    }

    // Search bar
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        radius: Common.Appearance.rounding.large
        color: Common.Appearance.m3colors.surfaceVariant

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Common.Appearance.spacing.medium
            anchors.rightMargin: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.small

            Common.Icon {
                name: Common.Icons.icons.search
                size: Common.Appearance.sizes.iconMedium
                color: Common.Appearance.m3colors.onSurfaceVariant
            }

            TextInput {
                id: searchInput
                Layout.fillWidth: true
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.normal
                color: Common.Appearance.m3colors.onSurface
                clip: true

                property string placeholderText: "Search applications..."

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: searchInput.placeholderText
                    font: searchInput.font
                    color: Common.Appearance.m3colors.onSurfaceVariant
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
            }

            // Clear button
            MouseArea {
                visible: searchInput.text !== ""
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                cursorShape: Qt.PointingHandCursor
                onClicked: searchInput.text = ""

                Common.Icon {
                    anchors.centerIn: parent
                    name: Common.Icons.icons.close
                    size: Common.Appearance.sizes.iconSmall
                    color: Common.Appearance.m3colors.onSurfaceVariant
                }
            }
        }
    }

    // App grid/list
    ListView {
        id: appListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 2

        model: root.isSearching ? searchResults : allApps

        delegate: MouseArea {
            id: appDelegate
            required property var modelData
            required property int index

            width: appListView.width
            height: 48
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: launchApp(modelData)

            Rectangle {
                anchors.fill: parent
                radius: Common.Appearance.rounding.medium
                color: appDelegate.containsMouse || appListView.currentIndex === appDelegate.index
                    ? Common.Appearance.m3colors.surfaceVariant
                    : "transparent"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Common.Appearance.spacing.medium
                anchors.rightMargin: Common.Appearance.spacing.medium
                spacing: Common.Appearance.spacing.medium

                // App icon with letter fallback
                Item {
                    id: iconContainer
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32

                    property string iconSource: modelData.icon || ""

                    Image {
                        id: appIcon
                        anchors.fill: parent
                        source: iconContainer.iconSource
                        sourceSize: Qt.size(32, 32)
                        smooth: true
                        visible: status === Image.Ready
                    }

                    // Fallback: Letter icon
                    Rectangle {
                        anchors.fill: parent
                        visible: appIcon.status !== Image.Ready
                        radius: Common.Appearance.rounding.small
                        color: Common.Appearance.m3colors.primaryContainer

                        Text {
                            anchors.centerIn: parent
                            text: modelData.name ? modelData.name.charAt(0).toUpperCase() : "?"
                            font.pixelSize: 16
                            font.bold: true
                            color: Common.Appearance.m3colors.onPrimaryContainer
                        }
                    }
                }

                // App info
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: modelData.name || "Unknown"
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.normal
                        color: Common.Appearance.m3colors.onSurface
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: text !== "" && text !== modelData.name
                        text: modelData.description || modelData.genericName || ""
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.m3colors.onSurfaceVariant
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Empty state
        Text {
            anchors.centerIn: parent
            visible: appListView.count === 0
            text: root.isSearching ? "No applications found" : "Loading applications..."
            font.family: Common.Appearance.fonts.main
            font.pixelSize: Common.Appearance.fontSize.normal
            color: Common.Appearance.m3colors.onSurfaceVariant
        }

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }

    // Handle Datacube query results
    Connections {
        target: Services.Datacube

        function onQueryCompleted(queryId, results) {
            if (queryId === root.allAppsQueryId) {
                // Reset retry count on success
                root.retryCount = 0
                // Sort alphabetically by name
                results.sort((a, b) => {
                    const nameA = (a.name || "").toLowerCase()
                    const nameB = (b.name || "").toLowerCase()
                    if (nameA < nameB) return -1
                    if (nameA > nameB) return 1
                    return 0
                })
                root.allApps = results
            } else if (queryId === root.searchQueryId) {
                root.searchResults = results
            }
        }

        function onQueryFailed(queryId, error) {
            console.log("Datacube query failed:", queryId, error)
            // If the allApps query failed, retry after a delay (service may have restarted)
            if (queryId === root.allAppsQueryId && root.retryCount < root.maxRetries) {
                root.retryCount++
                console.log("Datacube: retrying allApps query (attempt", root.retryCount, "of", root.maxRetries, ")")
                retryTimer.start()
            }
        }
    }

    // Retry timer for failed queries (datacube service may have restarted)
    Timer {
        id: retryTimer
        interval: 1000 * root.retryCount  // Exponential backoff: 1s, 2s, 3s, etc.
        repeat: false
        onTriggered: {
            root.loadAllApps()
        }
    }

    // Debounce timer for search queries
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
            // Cancel previous search if still running
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

        // Check if terminal app - handle boolean or string "true"/"false"
        const isTerminal = metadata.terminal === true || metadata.terminal === "true"
        const source = app?.source || "native"

        if (isTerminal) {
            // Terminal apps: launch with ghostty
            appLaunchProcess.command = ["ghostty", "-e", desktopId]
        } else if (source === "flatpak") {
            // Flatpak apps: use flatpak run
            appLaunchProcess.command = ["flatpak", "run", desktopId]
        } else {
            // Native apps: use gtk4-launch with desktop_id
            appLaunchProcess.command = ["gtk4-launch", desktopId]
        }
        // Launch detached so apps survive shell restart and run independently
        appLaunchProcess.startDetached()

        Root.GlobalStates.sidebarLeftOpen = false
        searchInput.text = ""
    }

    // App launcher process - used with startDetached() for independent execution
    Process {
        id: appLaunchProcess
        command: ["true"]
    }

    // Handle sidebar state changes
    Connections {
        target: Root.GlobalStates
        function onSidebarLeftOpenChanged() {
            if (Root.GlobalStates.sidebarLeftOpen) {
                // Refresh apps if list is empty (datacube may have restarted)
                if (root.allApps.length === 0) {
                    root.retryCount = 0
                    root.loadAllApps()
                }
            } else {
                // Reset state when sidebar closes
                searchInput.text = ""
                searchResults = []
            }
        }
    }

    // Focus search input - called externally by Loader
    function focusSearch() {
        searchInput.forceActiveFocus()
        appListView.currentIndex = 0
    }
}
