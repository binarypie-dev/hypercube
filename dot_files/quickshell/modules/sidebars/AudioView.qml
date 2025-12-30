import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import "../common" as Common
import "../../services" as Services
import "../../" as Root

// Audio settings view for the right sidebar
ColumnLayout {
    id: root
    spacing: Common.Appearance.spacing.large

    // Refresh devices when view opens
    Component.onCompleted: Services.Audio.refreshDevices()

    // Header with close button
    RowLayout {
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        Text {
            Layout.fillWidth: true
            text: "Audio"
            font.family: Common.Appearance.fonts.main
            font.pixelSize: Common.Appearance.fontSize.headline
            font.weight: Font.Medium
            color: Common.Appearance.m3colors.onSurface
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

            Text {
                anchors.centerIn: parent
                text: Common.Icons.icons.close
                font.family: Common.Appearance.fonts.icon
                font.pixelSize: Common.Appearance.sizes.iconMedium
                color: Common.Appearance.m3colors.onSurface
            }
        }
    }

    // Output (Speaker) section
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: outputContent.implicitHeight + Common.Appearance.spacing.medium * 2
        radius: Common.Appearance.rounding.large
        color: Common.Appearance.m3colors.surfaceVariant

        ColumnLayout {
            id: outputContent
            anchors.fill: parent
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            // Header row with mute toggle
            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.medium

                Text {
                    text: Services.Audio.muted
                        ? Common.Icons.icons.volumeOff
                        : Common.Icons.volumeIcon(Services.Audio.volume * 100, false)
                    font.family: Common.Appearance.fonts.icon
                    font.pixelSize: Common.Appearance.sizes.iconLarge
                    color: Services.Audio.muted
                        ? Common.Appearance.m3colors.onSurfaceVariant
                        : Common.Appearance.m3colors.primary
                }

                ColumnLayout {
                    spacing: 2

                    Text {
                        text: "Speaker"
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.normal
                        font.weight: Font.Medium
                        color: Common.Appearance.m3colors.onSurface
                    }

                    Text {
                        text: Services.Audio.muted
                            ? "Muted"
                            : Math.round(Services.Audio.volume * 100) + "%"
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.m3colors.onSurfaceVariant
                    }
                }

                Item { Layout.fillWidth: true }

                // Mute toggle switch
                MouseArea {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 32
                    Layout.alignment: Qt.AlignRight
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.Audio.toggleMute()

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: !Services.Audio.muted
                            ? Common.Appearance.m3colors.primary
                            : Common.Appearance.m3colors.surfaceVariant
                        border.width: !Services.Audio.muted ? 0 : 2
                        border.color: Common.Appearance.m3colors.outline

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        Rectangle {
                            width: !Services.Audio.muted ? 24 : 16
                            height: !Services.Audio.muted ? 24 : 16
                            radius: height / 2
                            anchors.verticalCenter: parent.verticalCenter
                            x: !Services.Audio.muted ? parent.width - width - 4 : 4
                            color: !Services.Audio.muted
                                ? Common.Appearance.m3colors.onPrimary
                                : Common.Appearance.m3colors.outline

                            Behavior on x {
                                NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                            }
                            Behavior on width {
                                NumberAnimation { duration: 150 }
                            }
                            Behavior on height {
                                NumberAnimation { duration: 150 }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                    }
                }
            }

            // Volume slider
            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.small

                Text {
                    text: Common.Icons.icons.volumeLow
                    font.family: Common.Appearance.fonts.icon
                    font.pixelSize: Common.Appearance.sizes.iconSmall
                    color: Common.Appearance.m3colors.onSurfaceVariant
                }

                // Custom slider using MouseArea
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32

                    Rectangle {
                        id: volumeTrack
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 6
                        radius: 3
                        color: Common.Appearance.m3colors.outline

                        Rectangle {
                            width: Services.Audio.volume * parent.width
                            height: parent.height
                            radius: 3
                            color: Common.Appearance.m3colors.primary
                        }
                    }

                    Rectangle {
                        id: volumeHandle
                        width: 20
                        height: 20
                        radius: 10
                        x: Services.Audio.volume * (parent.width - width)
                        anchors.verticalCenter: parent.verticalCenter
                        color: Common.Appearance.m3colors.primaryContainer
                        border.color: Common.Appearance.m3colors.primary
                        border.width: 2
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: updateVolume(mouse)
                        onPositionChanged: if (pressed) updateVolume(mouse)

                        function updateVolume(mouse) {
                            let newValue = Math.max(0, Math.min(1, mouse.x / width))
                            Services.Audio.setVolume(newValue)
                        }
                    }
                }

                Text {
                    text: Common.Icons.icons.volumeHigh
                    font.family: Common.Appearance.fonts.icon
                    font.pixelSize: Common.Appearance.sizes.iconSmall
                    color: Common.Appearance.m3colors.onSurfaceVariant
                }
            }

            // Output device selector
            DeviceSelector {
                Layout.fillWidth: true
                label: "Output Device"
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
        Layout.preferredHeight: inputContent.implicitHeight + Common.Appearance.spacing.medium * 2
        radius: Common.Appearance.rounding.large
        color: Common.Appearance.m3colors.surfaceVariant

        ColumnLayout {
            id: inputContent
            anchors.fill: parent
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            // Header row with mute toggle
            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.medium

                Text {
                    text: Services.Audio.micMuted
                        ? Common.Icons.icons.micOff
                        : Common.Icons.icons.mic
                    font.family: Common.Appearance.fonts.icon
                    font.pixelSize: Common.Appearance.sizes.iconLarge
                    color: Services.Privacy.micInUse
                        ? Common.Appearance.m3colors.error
                        : (Services.Audio.micMuted
                            ? Common.Appearance.m3colors.onSurfaceVariant
                            : Common.Appearance.m3colors.primary)
                }

                ColumnLayout {
                    spacing: 2

                    Text {
                        text: "Microphone"
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.normal
                        font.weight: Font.Medium
                        color: Common.Appearance.m3colors.onSurface
                    }

                    Text {
                        text: {
                            if (Services.Audio.micMuted && Services.Privacy.micInUse) {
                                return "Muted (in use)"
                            } else if (Services.Audio.micMuted) {
                                return "Muted"
                            } else if (Services.Privacy.micInUse) {
                                return "In use - " + Math.round(Services.Audio.micVolume * 100) + "%"
                            } else {
                                return Math.round(Services.Audio.micVolume * 100) + "%"
                            }
                        }
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Services.Privacy.micInUse
                            ? Common.Appearance.m3colors.error
                            : Common.Appearance.m3colors.onSurfaceVariant
                    }
                }

                Item { Layout.fillWidth: true }

                // Mute toggle switch
                MouseArea {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 32
                    Layout.alignment: Qt.AlignRight
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.Audio.toggleMicMute()

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: !Services.Audio.micMuted
                            ? Common.Appearance.m3colors.primary
                            : Common.Appearance.m3colors.surfaceVariant
                        border.width: !Services.Audio.micMuted ? 0 : 2
                        border.color: Common.Appearance.m3colors.outline

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }

                        Rectangle {
                            width: !Services.Audio.micMuted ? 24 : 16
                            height: !Services.Audio.micMuted ? 24 : 16
                            radius: height / 2
                            anchors.verticalCenter: parent.verticalCenter
                            x: !Services.Audio.micMuted ? parent.width - width - 4 : 4
                            color: !Services.Audio.micMuted
                                ? Common.Appearance.m3colors.onPrimary
                                : Common.Appearance.m3colors.outline

                            Behavior on x {
                                NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                            }
                            Behavior on width {
                                NumberAnimation { duration: 150 }
                            }
                            Behavior on height {
                                NumberAnimation { duration: 150 }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                    }
                }
            }

            // Mic volume slider
            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.small

                Text {
                    text: Common.Icons.icons.micOff
                    font.family: Common.Appearance.fonts.icon
                    font.pixelSize: Common.Appearance.sizes.iconSmall
                    color: Common.Appearance.m3colors.onSurfaceVariant
                }

                // Custom slider using MouseArea
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32

                    property color accentColor: Services.Privacy.micInUse
                        ? Common.Appearance.m3colors.error
                        : Common.Appearance.m3colors.primary

                    Rectangle {
                        id: micTrack
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 6
                        radius: 3
                        color: Common.Appearance.m3colors.outline

                        Rectangle {
                            width: Services.Audio.micVolume * parent.width
                            height: parent.height
                            radius: 3
                            color: parent.parent.accentColor
                        }
                    }

                    Rectangle {
                        id: micHandle
                        width: 20
                        height: 20
                        radius: 10
                        x: Services.Audio.micVolume * (parent.width - width)
                        anchors.verticalCenter: parent.verticalCenter
                        color: Common.Appearance.m3colors.primaryContainer
                        border.color: parent.accentColor
                        border.width: 2
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: updateMicVolume(mouse)
                        onPositionChanged: if (pressed) updateMicVolume(mouse)

                        function updateMicVolume(mouse) {
                            let newValue = Math.max(0, Math.min(1, mouse.x / width))
                            Services.Audio.setMicVolume(newValue)
                        }
                    }
                }

                Text {
                    text: Common.Icons.icons.mic
                    font.family: Common.Appearance.fonts.icon
                    font.pixelSize: Common.Appearance.sizes.iconSmall
                    color: Common.Appearance.m3colors.onSurfaceVariant
                }
            }

            // Input device selector
            DeviceSelector {
                Layout.fillWidth: true
                label: "Input Device"
                devices: Services.Audio.sources
                onDeviceSelected: function(name) {
                    Services.Audio.setDefaultSource(name)
                }
            }
        }
    }

    // Spacer
    Item { Layout.fillHeight: true }

    // Device selector dropdown component
    component DeviceSelector: ColumnLayout {
        id: selector
        property string label: ""
        property var devices: []
        property bool expanded: false

        signal deviceSelected(string name)

        spacing: Common.Appearance.spacing.small

        // Current selection / dropdown trigger
        MouseArea {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: selector.expanded = !selector.expanded

            Rectangle {
                anchors.fill: parent
                radius: Common.Appearance.rounding.medium
                color: parent.containsMouse ? Common.Appearance.surfaceLayer(2) : Common.Appearance.surfaceLayer(1)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Common.Appearance.spacing.small
                anchors.rightMargin: Common.Appearance.spacing.small
                spacing: Common.Appearance.spacing.small

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: selector.label
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.m3colors.onSurfaceVariant
                    }

                    Text {
                        Layout.fillWidth: true
                        text: {
                            for (let i = 0; i < selector.devices.length; i++) {
                                if (selector.devices[i].isDefault) {
                                    return selector.devices[i].description
                                }
                            }
                            return "No device"
                        }
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.normal
                        color: Common.Appearance.m3colors.onSurface
                        elide: Text.ElideRight
                    }
                }

                Text {
                    text: selector.expanded ? Common.Icons.icons.expand : Common.Icons.icons.collapse
                    font.family: Common.Appearance.fonts.icon
                    font.pixelSize: Common.Appearance.sizes.iconSmall
                    color: Common.Appearance.m3colors.onSurfaceVariant
                }
            }
        }

        // Dropdown list
        ColumnLayout {
            visible: selector.expanded
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: selector.devices

                MouseArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: {
                        selector.deviceSelected(modelData.name)
                        selector.expanded = false
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Common.Appearance.rounding.small
                        color: modelData.isDefault
                            ? Common.Appearance.m3colors.primaryContainer
                            : (parent.containsMouse ? Common.Appearance.surfaceLayer(2) : "transparent")
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Common.Appearance.spacing.small
                        anchors.rightMargin: Common.Appearance.spacing.small
                        spacing: Common.Appearance.spacing.small

                        Text {
                            Layout.fillWidth: true
                            text: modelData.description
                            font.family: Common.Appearance.fonts.main
                            font.pixelSize: Common.Appearance.fontSize.normal
                            color: modelData.isDefault
                                ? Common.Appearance.m3colors.onPrimaryContainer
                                : Common.Appearance.m3colors.onSurface
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: modelData.isDefault
                            text: Common.Icons.icons.check
                            font.family: Common.Appearance.fonts.icon
                            font.pixelSize: Common.Appearance.sizes.iconSmall
                            color: Common.Appearance.m3colors.onPrimaryContainer
                        }
                    }
                }
            }
        }
    }
}
