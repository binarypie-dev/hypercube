import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../common" as Common
import "../../" as Root
import "../../services" as Services

PanelWindow {
    id: root

    required property var targetScreen
    screen: targetScreen

    anchors {
        top: true
        bottom: true
        left: true
    }

    margins.top: Common.Appearance.sizes.barHeight

    implicitWidth: Common.Appearance.sizes.sidebarWidth
    color: "transparent"

    visible: Root.GlobalStates.sidebarLeftOpen

    // Request keyboard focus from compositor
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "sidebar"

    // State for search results
    property var searchResults: []
    property var allApps: []
    property string currentQuery: ""
    property bool isSearching: false

    // Background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(
            Common.Appearance.m3colors.surface.r,
            Common.Appearance.m3colors.surface.g,
            Common.Appearance.m3colors.surface.b,
            Common.Appearance.panelOpacity
        )
    }

    // Content
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Common.Appearance.spacing.medium
        spacing: Common.Appearance.spacing.medium

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
    }

    // Track the query we're waiting for results from
    property string allAppsQueryId: ""
    property string searchQueryId: ""

    // Load all apps on startup
    Component.onCompleted: {
        allAppsQueryId = Services.Datacube.queryApplications("", 500)
    }

    // Handle Datacube query results
    Connections {
        target: Services.Datacube

        function onQueryCompleted(queryId, results) {
            if (queryId === root.allAppsQueryId) {
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

        if (isTerminal) {
            // Terminal apps: launch with ghostty
            appLaunchProcess.command = ["ghostty", "-e", desktopId]
        } else {
            // GUI apps: use gtk-launch with desktop_id
            appLaunchProcess.command = ["gtk-launch", desktopId]
        }
        appLaunchProcess.running = true

        Root.GlobalStates.sidebarLeftOpen = false
        searchInput.text = ""
    }

    // App launcher process
    Process {
        id: appLaunchProcess
        command: ["true"]
    }

    // Focus search when sidebar opens
    onVisibleChanged: {
        if (visible) {
            searchInput.forceActiveFocus()
            appListView.currentIndex = 0
        } else {
            searchInput.text = ""
            searchResults = []
        }
    }
}
