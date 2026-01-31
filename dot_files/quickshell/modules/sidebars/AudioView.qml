import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import "../common" as Common
import "../../services" as Services
import "../../" as Root

// Audio settings view - TUI style
ColumnLayout {
    id: root
    spacing: Common.Appearance.spacing.medium
    anchors.topMargin: 5
    anchors.bottomMargin: 5

    Component.onCompleted: Services.Audio.refreshDevices()

    // Header
    Text {
        Layout.fillWidth: true
        text: "Audio"
        font.family: Common.Appearance.fonts.mono
        font.pixelSize: Common.Appearance.fontSize.large
        font.bold: true
        color: Common.Appearance.colors.fg
    }

    // Output (Speaker) section
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: outputContent.height + Common.Appearance.spacing.medium * 2
        color: Common.Appearance.colors.bgDark
        border.width: 1
        border.color: Common.Appearance.colors.border
        radius: Common.Appearance.rounding.tiny

        ColumnLayout {
            id: outputContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            // Section header
            Text {
                text: "Output"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                font.bold: true
                color: Common.Appearance.colors.fgDark
            }

            // Speaker header row
            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.medium

                Common.Icon {
                    name: Common.Icons.volumeIcon(Services.Audio.volume * 100, Services.Audio.muted)
                    size: 20
                    color: Services.Audio.muted
                        ? Common.Appearance.colors.fgDark
                        : Common.Appearance.colors.fg
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "Speaker"
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.normal
                        font.bold: true
                        color: Common.Appearance.colors.fg
                    }

                    Text {
                        text: Services.Audio.muted
                            ? "[MUTED]"
                            : "[" + Math.round(Services.Audio.volume * 100) + "%]"
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Services.Audio.muted
                            ? Common.Appearance.colors.red
                            : Common.Appearance.colors.fgDark
                    }
                }

                Common.TuiToggle {
                    checked: !Services.Audio.muted
                    onToggled: Services.Audio.toggleMute()
                }
            }

            // Volume slider
            Common.TuiSlider {
                Layout.fillWidth: true
                value: Services.Audio.volume
                accentColor: Common.Appearance.colors.blue
                onMoved: function(newValue) {
                    Services.Audio.setVolume(newValue)
                }
            }

            // Output device selector
            DeviceSelector {
                Layout.fillWidth: true
                devices: Services.Audio.sinks
                onDeviceSelected: function(name) {
                    Services.Audio.setDefaultSink(name)
                }
            }
        }
    }

    // Input (Microphone) section
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: inputContent.height + Common.Appearance.spacing.medium * 2
        color: Common.Appearance.colors.bgDark
        border.width: 1
        border.color: Common.Appearance.colors.border
        radius: Common.Appearance.rounding.tiny

        ColumnLayout {
            id: inputContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            // Section header
            Text {
                text: "Input"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                font.bold: true
                color: Common.Appearance.colors.fgDark
            }

            // Mic header row
            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.medium

                Common.Icon {
                    name: Services.Audio.micMuted ? Common.Icons.icons.micOff : Common.Icons.icons.mic
                    size: 20
                    color: Services.Privacy.micInUse
                        ? Common.Appearance.colors.red
                        : (Services.Audio.micMuted
                            ? Common.Appearance.colors.fgDark
                            : Common.Appearance.colors.fg)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "Microphone"
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.normal
                        font.bold: true
                        color: Common.Appearance.colors.fg
                    }

                    Text {
                        text: {
                            if (Services.Audio.micMuted && Services.Privacy.micInUse) {
                                return "[MUTED] (in use)"
                            } else if (Services.Audio.micMuted) {
                                return "[MUTED]"
                            } else if (Services.Privacy.micInUse) {
                                return "[" + Math.round(Services.Audio.micVolume * 100) + "%] (in use)"
                            } else {
                                return "[" + Math.round(Services.Audio.micVolume * 100) + "%]"
                            }
                        }
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Services.Privacy.micInUse
                            ? Common.Appearance.colors.red
                            : (Services.Audio.micMuted
                                ? Common.Appearance.colors.red
                                : Common.Appearance.colors.fgDark)
                    }
                }

                Common.TuiToggle {
                    checked: !Services.Audio.micMuted
                    onToggled: Services.Audio.toggleMicMute()
                }
            }

            // Mic volume slider
            Common.TuiSlider {
                Layout.fillWidth: true
                value: Services.Audio.micVolume
                accentColor: Services.Privacy.micInUse
                    ? Common.Appearance.colors.red
                    : Common.Appearance.colors.blue
                onMoved: function(newValue) {
                    Services.Audio.setMicVolume(newValue)
                }
            }

            // Input device selector
            DeviceSelector {
                Layout.fillWidth: true
                devices: Services.Audio.sources
                onDeviceSelected: function(name) {
                    Services.Audio.setDefaultSource(name)
                }
            }
        }
    }

    // Spacer
    Item { Layout.fillHeight: true }

    // Device selector component
    component DeviceSelector: ColumnLayout {
        id: selector
        property var devices: []
        property bool expanded: false

        signal deviceSelected(string name)

        spacing: Common.Appearance.spacing.small

        // Current selection / dropdown trigger
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: selectorMouse.containsMouse
                ? Common.Appearance.colors.bgHighlight
                : "transparent"
            border.width: 1
            border.color: Common.Appearance.colors.border
            radius: Common.Appearance.rounding.tiny

            MouseArea {
                id: selectorMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: selector.expanded = !selector.expanded
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Common.Appearance.spacing.small
                anchors.rightMargin: Common.Appearance.spacing.small
                spacing: Common.Appearance.spacing.small

                Text {
                    Layout.fillWidth: true
                    text: {
                        for (let i = 0; i < selector.devices.length; i++) {
                            if (selector.devices[i].isDefault) {
                                return selector.devices[i].description
                            }
                        }
                        return "-- No device --"
                    }
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Common.Appearance.colors.fg
                    elide: Text.ElideRight
                }

                Common.Icon {
                    name: selector.expanded ? Common.Icons.icons.collapse : Common.Icons.icons.expand
                    size: 12
                    color: Common.Appearance.colors.fgDark
                }
            }
        }

        // Dropdown list
        ColumnLayout {
            visible: selector.expanded
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: selector.devices

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    color: deviceMouse.containsMouse
                        ? Common.Appearance.colors.bgHighlight
                        : (modelData.isDefault ? Common.Appearance.colors.bgVisual : "transparent")

                    MouseArea {
                        id: deviceMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            selector.deviceSelected(modelData.name)
                            selector.expanded = false
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Common.Appearance.spacing.medium
                        anchors.rightMargin: Common.Appearance.spacing.medium

                        Text {
                            Layout.fillWidth: true
                            text: modelData.description
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.colors.fg
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: modelData.isDefault
                            text: "[*]"
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.small
                            font.bold: true
                            color: Common.Appearance.colors.cyan
                        }
                    }
                }
            }
        }
    }
}
