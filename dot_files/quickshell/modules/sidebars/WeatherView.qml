import QtQuick
import QtQuick.Layouts
import Quickshell

import "../common" as Common
import "../../services" as Services
import "../../" as Root

// Weather view for the right sidebar
ColumnLayout {
    id: root
    spacing: Common.Appearance.spacing.large

    // Track if we're editing location
    property bool editingLocation: false
    property string pendingLocation: Common.Config.weatherLocation

    // Header with close button
    RowLayout {
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        Text {
            Layout.fillWidth: true
            text: "Weather"
            font.family: Common.Appearance.fonts.main
            font.pixelSize: Common.Appearance.fontSize.headline
            font.weight: Font.Medium
            color: Common.Appearance.m3colors.onSurface
        }

        // Refresh button
        MouseArea {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: Services.Weather.refresh()

            Rectangle {
                anchors.fill: parent
                radius: Common.Appearance.rounding.small
                color: parent.containsMouse ? Common.Appearance.m3colors.surfaceVariant : "transparent"
            }

            Common.Icon {
                anchors.centerIn: parent
                name: Common.Icons.icons.refresh
                size: Common.Appearance.sizes.iconMedium
                color: Common.Appearance.m3colors.onSurface

                RotationAnimation on rotation {
                    running: Services.Weather.loading
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
            }
        }

        MouseArea {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: Root.GlobalStates.sidebarRightOpen = false

            Rectangle {
                anchors.fill: parent
                radius: Common.Appearance.rounding.small
                color: parent.containsMouse ? Common.Appearance.m3colors.surfaceVariant : "transparent"
            }

            Common.Icon {
                anchors.centerIn: parent
                name: Common.Icons.icons.close
                size: Common.Appearance.sizes.iconMedium
                color: Common.Appearance.m3colors.onSurface
            }
        }
    }

    // Loading state
    Rectangle {
        visible: !Services.Weather.ready && Services.Weather.loading
        Layout.fillWidth: true
        Layout.preferredHeight: 100
        radius: Common.Appearance.rounding.large
        color: Common.Appearance.m3colors.surfaceVariant

        Text {
            anchors.centerIn: parent
            text: "Loading weather..."
            font.family: Common.Appearance.fonts.main
            font.pixelSize: Common.Appearance.fontSize.normal
            color: Common.Appearance.m3colors.onSurfaceVariant
        }
    }

    // Error state
    Rectangle {
        visible: Services.Weather.error !== ""
        Layout.fillWidth: true
        Layout.preferredHeight: errorColumn.implicitHeight + Common.Appearance.spacing.medium * 2
        radius: Common.Appearance.rounding.large
        color: Common.Appearance.m3colors.errorContainer

        ColumnLayout {
            id: errorColumn
            anchors.fill: parent
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.small

            Text {
                Layout.fillWidth: true
                text: "Unable to load weather"
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.normal
                font.weight: Font.Medium
                color: Common.Appearance.m3colors.onErrorContainer
            }

            Text {
                Layout.fillWidth: true
                text: Services.Weather.error
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.m3colors.onErrorContainer
                opacity: 0.8
                wrapMode: Text.WordWrap
            }
        }
    }

    // Current weather card
    Rectangle {
        visible: Services.Weather.ready
        Layout.fillWidth: true
        Layout.preferredHeight: currentWeatherColumn.implicitHeight + Common.Appearance.spacing.medium * 2
        radius: Common.Appearance.rounding.large
        color: Common.Appearance.m3colors.primaryContainer

        ColumnLayout {
            id: currentWeatherColumn
            anchors.fill: parent
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            // Temperature and icon row
            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.medium

                Common.Icon {
                    name: Common.Icons.weatherIcon(Services.Weather.condition, Services.Weather.isNight)
                    size: 64
                    color: Common.Appearance.m3colors.onPrimaryContainer
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: Services.Weather.temperature
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.display
                        font.weight: Font.Medium
                        color: Common.Appearance.m3colors.onPrimaryContainer
                    }

                    Text {
                        text: Services.Weather.condition
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.normal
                        color: Common.Appearance.m3colors.onPrimaryContainer
                        opacity: 0.8
                    }
                }
            }

            // Location
            Text {
                visible: Services.Weather.location !== ""
                text: Services.Weather.location + (Services.Weather.region ? ", " + Services.Weather.region : "")
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.m3colors.onPrimaryContainer
                opacity: 0.7
            }
        }
    }

    // Weather details card
    Rectangle {
        visible: Services.Weather.ready
        Layout.fillWidth: true
        Layout.preferredHeight: detailsGrid.implicitHeight + Common.Appearance.spacing.medium * 2
        radius: Common.Appearance.rounding.large
        color: Common.Appearance.m3colors.surfaceVariant

        GridLayout {
            id: detailsGrid
            anchors.fill: parent
            anchors.margins: Common.Appearance.spacing.medium
            columns: 2
            rowSpacing: Common.Appearance.spacing.medium
            columnSpacing: Common.Appearance.spacing.medium

            // Feels like
            WeatherDetailItem {
                Layout.fillWidth: true
                icon: "thermometer"
                label: "Feels like"
                value: Services.Weather.feelsLike
            }

            // Humidity
            WeatherDetailItem {
                Layout.fillWidth: true
                icon: "droplets"
                label: "Humidity"
                value: Services.Weather.humidity + "%"
            }

            // Wind
            WeatherDetailItem {
                Layout.fillWidth: true
                icon: "wind"
                label: "Wind"
                value: Services.Weather.windSpeed + " " + Services.Weather.windDirection
            }

            // Visibility
            WeatherDetailItem {
                Layout.fillWidth: true
                icon: "eye"
                label: "Visibility"
                value: Services.Weather.visibility
            }

            // Pressure
            WeatherDetailItem {
                Layout.fillWidth: true
                icon: "gauge"
                label: "Pressure"
                value: Services.Weather.pressure
            }

            // UV Index
            WeatherDetailItem {
                visible: Services.Weather.uvIndex !== ""
                Layout.fillWidth: true
                icon: "sun"
                label: "UV Index"
                value: Services.Weather.uvIndex
            }
        }
    }

    // Location settings card
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: locationColumn.implicitHeight + Common.Appearance.spacing.medium * 2
        radius: Common.Appearance.rounding.large
        color: Common.Appearance.m3colors.surfaceVariant

        ColumnLayout {
            id: locationColumn
            anchors.fill: parent
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            Text {
                text: "Location Settings"
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.normal
                font.weight: Font.Medium
                color: Common.Appearance.m3colors.onSurface
            }

            // Location input
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: Common.Appearance.rounding.medium
                color: Common.Appearance.m3colors.surface
                border.width: locationInput.activeFocus ? 2 : 1
                border.color: locationInput.activeFocus
                    ? Common.Appearance.m3colors.primary
                    : Common.Appearance.m3colors.outline

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Common.Appearance.spacing.medium
                    anchors.rightMargin: Common.Appearance.spacing.small
                    spacing: Common.Appearance.spacing.small

                    Common.Icon {
                        name: "map-pin"
                        size: Common.Appearance.sizes.iconMedium
                        color: locationInput.activeFocus
                            ? Common.Appearance.m3colors.primary
                            : Common.Appearance.m3colors.onSurfaceVariant
                    }

                    TextInput {
                        id: locationInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.normal
                        color: Common.Appearance.m3colors.onSurface
                        selectionColor: Common.Appearance.m3colors.primary
                        selectedTextColor: Common.Appearance.m3colors.onPrimary
                        clip: true
                        text: root.pendingLocation

                        onTextChanged: {
                            root.pendingLocation = text
                            root.editingLocation = (text !== Common.Config.weatherLocation)
                        }

                        // Placeholder
                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 0
                            verticalAlignment: Text.AlignVCenter
                            visible: !locationInput.text && !locationInput.activeFocus
                            text: "Auto-detect (leave empty)"
                            font: locationInput.font
                            color: Common.Appearance.m3colors.onSurfaceVariant
                            opacity: 0.6
                        }
                    }

                    // Clear button
                    MouseArea {
                        visible: locationInput.text !== ""
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            locationInput.text = ""
                            locationInput.forceActiveFocus()
                        }

                        Common.Icon {
                            anchors.centerIn: parent
                            name: Common.Icons.icons.close
                            size: Common.Appearance.sizes.iconSmall
                            color: Common.Appearance.m3colors.onSurfaceVariant
                        }
                    }
                }
            }

            // Units toggle
            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.medium

                Text {
                    Layout.fillWidth: true
                    text: "Temperature units"
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.normal
                    color: Common.Appearance.m3colors.onSurface
                }

                // Segmented button for units
                Rectangle {
                    Layout.preferredWidth: unitsRow.implicitWidth
                    Layout.preferredHeight: 36
                    radius: Common.Appearance.rounding.medium
                    color: Common.Appearance.m3colors.surface

                    RowLayout {
                        id: unitsRow
                        anchors.fill: parent
                        spacing: 0

                        // Metric button
                        MouseArea {
                            Layout.preferredWidth: 70
                            Layout.fillHeight: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Common.Config.weatherUnits = "metric"
                                root.editingLocation = true
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: Common.Appearance.rounding.small
                                color: Common.Config.weatherUnits === "metric"
                                    ? Common.Appearance.m3colors.primaryContainer
                                    : "transparent"
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "°C"
                                font.family: Common.Appearance.fonts.main
                                font.pixelSize: Common.Appearance.fontSize.normal
                                font.weight: Common.Config.weatherUnits === "metric" ? Font.Medium : Font.Normal
                                color: Common.Config.weatherUnits === "metric"
                                    ? Common.Appearance.m3colors.onPrimaryContainer
                                    : Common.Appearance.m3colors.onSurface
                            }
                        }

                        // Imperial button
                        MouseArea {
                            Layout.preferredWidth: 70
                            Layout.fillHeight: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Common.Config.weatherUnits = "imperial"
                                root.editingLocation = true
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: Common.Appearance.rounding.small
                                color: Common.Config.weatherUnits === "imperial"
                                    ? Common.Appearance.m3colors.primaryContainer
                                    : "transparent"
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "°F"
                                font.family: Common.Appearance.fonts.main
                                font.pixelSize: Common.Appearance.fontSize.normal
                                font.weight: Common.Config.weatherUnits === "imperial" ? Font.Medium : Font.Normal
                                color: Common.Config.weatherUnits === "imperial"
                                    ? Common.Appearance.m3colors.onPrimaryContainer
                                    : Common.Appearance.m3colors.onSurface
                            }
                        }
                    }
                }
            }

            // Save button (only visible when changes pending)
            MouseArea {
                visible: root.editingLocation
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: {
                    Common.Config.weatherLocation = root.pendingLocation
                    Common.Config.save()
                    root.editingLocation = false
                    Services.Weather.refresh()
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Common.Appearance.rounding.medium
                    color: parent.containsMouse
                        ? Qt.darker(Common.Appearance.m3colors.primary, 1.1)
                        : Common.Appearance.m3colors.primary
                }

                Text {
                    anchors.centerIn: parent
                    text: "Save & Refresh"
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.normal
                    font.weight: Font.Medium
                    color: Common.Appearance.m3colors.onPrimary
                }
            }
        }
    }

    // Spacer
    Item { Layout.fillHeight: true }

    // Attribution
    Text {
        Layout.fillWidth: true
        text: "Weather data from wttr.in"
        font.family: Common.Appearance.fonts.main
        font.pixelSize: Common.Appearance.fontSize.small
        color: Common.Appearance.m3colors.onSurfaceVariant
        opacity: 0.6
        horizontalAlignment: Text.AlignHCenter
    }

    // Weather detail item component
    component WeatherDetailItem: RowLayout {
        property string icon: ""
        property string label: ""
        property string value: ""

        spacing: Common.Appearance.spacing.small

        Common.Icon {
            name: parent.icon
            size: Common.Appearance.sizes.iconMedium
            color: Common.Appearance.m3colors.onSurfaceVariant
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: parent.parent.label
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.m3colors.onSurfaceVariant
            }

            Text {
                text: parent.parent.value
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.normal
                color: Common.Appearance.m3colors.onSurface
            }
        }
    }
}
