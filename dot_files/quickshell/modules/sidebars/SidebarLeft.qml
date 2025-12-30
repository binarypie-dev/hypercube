import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "../common" as Common
import "../../" as Root

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
    property string currentQuery: ""

    // Background (slide animation applied to content instead of window)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(
            Common.Appearance.m3colors.surface.r,
            Common.Appearance.m3colors.surface.g,
            Common.Appearance.m3colors.surface.b,
            Common.Appearance.panelOpacity
        )

        // Right border
        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Common.Appearance.m3colors.outlineVariant
        }
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

                Text {
                    text: Common.Icons.icons.search
                    font.family: Common.Appearance.fonts.icon
                    font.pixelSize: Common.Appearance.sizes.iconMedium
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
                        queryDebounceTimer.restart()
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
                            launchApp(searchResults[appListView.currentIndex])
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

                    Text {
                        anchors.centerIn: parent
                        text: Common.Icons.icons.close
                        font.family: Common.Appearance.fonts.icon
                        font.pixelSize: Common.Appearance.sizes.iconSmall
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

            model: searchResults

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

                    // App icon with cascading fallback
                    Item {
                        id: iconContainer
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32

                        property string iconName: modelData._raw ? modelData._raw.icon : ""
                        property bool iconLoaded: primaryIcon.status === Image.Ready || flatpakIcon.status === Image.Ready

                        // Primary: Qt icon provider
                        Image {
                            id: primaryIcon
                            anchors.fill: parent
                            source: iconContainer.iconName ? "image://icon/" + iconContainer.iconName : ""
                            sourceSize: Qt.size(32, 32)
                            smooth: true
                            visible: status === Image.Ready
                        }

                        // Fallback 1: Flatpak icon path
                        Image {
                            id: flatpakIcon
                            anchors.fill: parent
                            source: primaryIcon.status === Image.Error && iconContainer.iconName
                                ? "file:///var/lib/flatpak/exports/share/icons/hicolor/128x128/apps/" + iconContainer.iconName + ".png"
                                : ""
                            sourceSize: Qt.size(32, 32)
                            smooth: true
                            visible: primaryIcon.status !== Image.Ready && status === Image.Ready
                        }

                        // Fallback 2: Letter icon
                        Rectangle {
                            anchors.fill: parent
                            visible: !iconContainer.iconLoaded
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
                text: searchInput.text ? "No applications found" : "Type to search..."
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
    property string activeQueryId: ""

    // Debounce timer for search queries
    Timer {
        id: queryDebounceTimer
        interval: 150
        onTriggered: {
            const query = root.currentQuery
            if (!query || query.trim() === "") {
                searchResults = []
                root.activeQueryId = ""
                return
            }
            // Generate a unique ID for this query
            root.activeQueryId = query + "_" + Date.now()
            datacubeQuery.queryId = root.activeQueryId
            datacubeQuery.query = query
            datacubeQuery.running = true
        }
    }

    // Datacube query process
    Process {
        id: datacubeQuery
        property string query: ""
        property string queryId: ""
        property var pendingResults: []
        command: ["bash", "-lc", "datacube-cli query '" + query.replace(/'/g, "'\\''") + "' --json -m 50"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (!data || data.trim() === "") return

                try {
                    const item = JSON.parse(data)
                    const result = {
                        id: item.id || "",
                        type: item.provider === "applications" ? "app" : item.provider,
                        name: item.text || "",
                        description: item.subtext || "",
                        genericName: item.subtext || "",
                        icon: getIconPath(item.icon),
                        exec: item.exec || "",
                        provider: item.provider || "",
                        score: item.score || 0,
                        _raw: item
                    }
                    datacubeQuery.pendingResults.push(result)
                } catch (e) {
                    console.log("Failed to parse datacube result:", e, data)
                }
            }
        }

        onStarted: {
            datacubeQuery.pendingResults = []
        }

        onExited: {
            // Only update results if this is still the active query
            if (datacubeQuery.queryId === root.activeQueryId) {
                root.searchResults = datacubeQuery.pendingResults
            }
        }
    }

    // Datacube activate process
    Process {
        id: datacubeActivate
        property string itemJson: ""
        command: ["bash", "-lc", "echo '" + itemJson + "' | datacube-cli activate --json"]
    }

    function getIconPath(iconName) {
        if (!iconName) return ""
        if (iconName.startsWith("/")) return "file://" + iconName
        // Try Qt icon provider first
        return "image://icon/" + iconName
    }

    // Try to find icon in flatpak exports if Qt icon provider fails
    function getFlatpakIconPath(iconName, size) {
        if (!iconName) return ""
        const sizes = [size || 128, 64, 48, 32, 256, 512]
        const basePath = "/var/lib/flatpak/exports/share/icons/hicolor/"

        for (const s of sizes) {
            const path = basePath + s + "x" + s + "/apps/" + iconName + ".png"
            return "file://" + path
        }
        return ""
    }

    function launchApp(app) {
        if (!app) return

        if (app._raw) {
            const itemJson = JSON.stringify(app._raw).replace(/'/g, "'\\''")
            datacubeActivate.itemJson = itemJson
            datacubeActivate.running = true
        } else if (app.exec) {
            appLaunchProcess.command = ["sh", "-c", app.exec]
            appLaunchProcess.running = true
        }

        Root.GlobalStates.sidebarLeftOpen = false
        searchInput.text = ""
    }

    // Fallback app launcher process
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
