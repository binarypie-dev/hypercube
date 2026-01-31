import QtQuick
import QtQuick.Layouts
import Quickshell

import "../common" as Common
import "../../services" as Services
import "../../" as Root

// Weather view - TUI style
ColumnLayout {
    id: root
    spacing: Common.Appearance.spacing.medium
    anchors.topMargin: 5
    anchors.bottomMargin: 5

    property bool editingLocation: false
    property string pendingLocation: Common.Config.weatherLocation

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        Text {
            Layout.fillWidth: true
            text: "Weather"
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.large
            font.bold: true
            color: Common.Appearance.colors.fg
        }

        Common.TuiButton {
            icon: Common.Icons.icons.refresh
            onClicked: Services.Weather.refresh()
        }
    }

    // Loading state
    Rectangle {
        visible: !Services.Weather.ready && Services.Weather.loading
        Layout.fillWidth: true
        Layout.preferredHeight: 60
        color: Common.Appearance.colors.bgDark
        border.width: 1
        border.color: Common.Appearance.colors.border
        radius: Common.Appearance.rounding.tiny

        Text {
            anchors.centerIn: parent
            text: "[Loading...]"
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.normal
            color: Common.Appearance.colors.cyan
        }
    }

    // Error state
    Rectangle {
        visible: Services.Weather.error !== ""
        Layout.fillWidth: true
        Layout.preferredHeight: errorContent.height + Common.Appearance.spacing.medium * 2
        color: Common.Appearance.colors.bgDark
        border.width: 1
        border.color: Common.Appearance.colors.red
        radius: Common.Appearance.rounding.tiny

        ColumnLayout {
            id: errorContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.small

            Text {
                text: "[ERROR]"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.normal
                font.bold: true
                color: Common.Appearance.colors.red
            }

            Text {
                Layout.fillWidth: true
                text: Services.Weather.error
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.colors.fgDark
                wrapMode: Text.WordWrap
            }
        }
    }

    // Current weather
    Rectangle {
        visible: Services.Weather.ready
        Layout.fillWidth: true
        Layout.preferredHeight: currentContent.height + Common.Appearance.spacing.medium * 2
        color: Common.Appearance.colors.bgDark
        border.width: 1
        border.color: Common.Appearance.colors.border
        radius: Common.Appearance.rounding.tiny

        ColumnLayout {
            id: currentContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            Text {
                text: "Current"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                font.bold: true
                color: Common.Appearance.colors.fgDark
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.medium

                Common.Icon {
                    name: Common.Icons.weatherIcon(Services.Weather.condition, Services.Weather.isNight)
                    size: 48
                    color: Common.Appearance.colors.cyan
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: Services.Weather.temperature
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.display
                        font.bold: true
                        color: Common.Appearance.colors.cyan
                    }

                    Text {
                        text: Services.Weather.condition
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.normal
                        color: Common.Appearance.colors.fgDark
                    }
                }
            }

            Text {
                visible: Services.Weather.location !== ""
                text: Services.Weather.location + (Services.Weather.region ? ", " + Services.Weather.region : "")
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.colors.comment
            }
        }
    }

    // Weather details
    Rectangle {
        visible: Services.Weather.ready
        Layout.fillWidth: true
        Layout.preferredHeight: detailsContent.height + Common.Appearance.spacing.medium * 2
        color: Common.Appearance.colors.bgDark
        border.width: 1
        border.color: Common.Appearance.colors.border
        radius: Common.Appearance.rounding.tiny

        ColumnLayout {
            id: detailsContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.small

            Text {
                text: "Details"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                font.bold: true
                color: Common.Appearance.colors.fgDark
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: Common.Appearance.spacing.small
                columnSpacing: Common.Appearance.spacing.medium

                WeatherDetail { label: "Feels like"; value: Services.Weather.feelsLike }
                WeatherDetail { label: "Humidity"; value: Services.Weather.humidity + "%" }
                WeatherDetail { label: "Wind"; value: Services.Weather.windSpeed + " " + Services.Weather.windDirection }
                WeatherDetail { label: "Visibility"; value: Services.Weather.visibility }
                WeatherDetail { label: "Pressure"; value: Services.Weather.pressure }
                WeatherDetail { label: "UV Index"; value: Services.Weather.uvIndex; visible: Services.Weather.uvIndex !== "" }
            }
        }
    }

    // Location settings
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: settingsContent.height + Common.Appearance.spacing.medium * 2
        color: Common.Appearance.colors.bgDark
        border.width: 1
        border.color: Common.Appearance.colors.border
        radius: Common.Appearance.rounding.tiny

        ColumnLayout {
            id: settingsContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            Text {
                text: "Settings"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                font.bold: true
                color: Common.Appearance.colors.fgDark
            }

            // Location input
            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.small

                Text {
                    text: "Location"
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Common.Appearance.colors.fgDark
                }

                Common.TuiInput {
                    id: locationInput
                    Layout.fillWidth: true
                    text: root.pendingLocation
                    placeholderText: "Auto-detect"

                    onTextChanged: {
                        root.pendingLocation = text
                        root.editingLocation = (text !== Common.Config.weatherLocation)
                    }
                }
            }

            // Units toggle
            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.medium

                Text {
                    text: "Units"
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Common.Appearance.colors.fgDark
                }

                Item { Layout.fillWidth: true }

                Common.TuiButton {
                    text: "°C"
                    primary: Common.Config.weatherUnits === "metric"
                    onClicked: {
                        Common.Config.weatherUnits = "metric"
                        root.editingLocation = true
                    }
                }

                Common.TuiButton {
                    text: "°F"
                    primary: Common.Config.weatherUnits === "imperial"
                    onClicked: {
                        Common.Config.weatherUnits = "imperial"
                        root.editingLocation = true
                    }
                }
            }

            // Save button
            Common.TuiButton {
                visible: root.editingLocation
                Layout.fillWidth: true
                text: "Save & Refresh"
                primary: true
                onClicked: {
                    Common.Config.weatherLocation = root.pendingLocation
                    Common.Config.save()
                    root.editingLocation = false
                    Services.Weather.refresh()
                }
            }
        }
    }

    // Spacer
    Item { Layout.fillHeight: true }

    // Attribution
    Text {
        Layout.fillWidth: true
        text: "Data from wttr.in"
        font.family: Common.Appearance.fonts.mono
        font.pixelSize: Common.Appearance.fontSize.small
        color: Common.Appearance.colors.comment
        horizontalAlignment: Text.AlignHCenter
    }

    // Weather Detail Component
    component WeatherDetail: RowLayout {
        property string label: ""
        property string value: ""

        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        Text {
            text: label
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.small
            color: Common.Appearance.colors.fgDark
        }

        Item { Layout.fillWidth: true }

        Text {
            text: value
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.small
            color: Common.Appearance.colors.fg
        }
    }

}
