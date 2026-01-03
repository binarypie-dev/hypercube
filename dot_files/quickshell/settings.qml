import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

import "modules/common" as Common

// Settings panel
PanelWindow {
    id: root

    required property var screen

    anchors.centerIn: true

    width: 600
    height: 500
    color: "transparent"

    visible: GlobalStates.settingsOpen

    // Fade animation
    opacity: GlobalStates.settingsOpen ? 1 : 0
    Behavior on opacity {
        NumberAnimation {
            duration: Common.Appearance.animation.standard
            easing.type: Easing.OutCubic
        }
    }

    // Background
    Rectangle {
        anchors.fill: parent
        radius: Common.Appearance.rounding.xlarge
        color: Qt.rgba(
            Common.Appearance.m3colors.surface.r,
            Common.Appearance.m3colors.surface.g,
            Common.Appearance.m3colors.surface.b,
            Common.Appearance.overlayOpacity
        )
        border.width: 1
        border.color: Common.Appearance.m3colors.outlineVariant
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Common.Appearance.spacing.large
        spacing: Common.Appearance.spacing.large

        // Navigation sidebar
        Rectangle {
            Layout.preferredWidth: 160
            Layout.fillHeight: true
            radius: Common.Appearance.rounding.large
            color: Common.Appearance.m3colors.surfaceVariant

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Common.Appearance.spacing.small
                spacing: 2

                // Header
                Text {
                    Layout.fillWidth: true
                    Layout.bottomMargin: Common.Appearance.spacing.small
                    text: "Settings"
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.large
                    font.weight: Font.Medium
                    color: Common.Appearance.m3colors.onSurface
                    horizontalAlignment: Text.AlignHCenter
                }

                Repeater {
                    model: [
                        { id: "appearance", label: "Appearance", icon: Common.Icons.icons.settings },
                        { id: "bar", label: "Status Bar", icon: Common.Icons.icons.menu },
                        { id: "notifications", label: "Notifications", icon: Common.Icons.icons.notification },
                        { id: "shortcuts", label: "Shortcuts", icon: Common.Icons.icons.code },
                        { id: "about", label: "About", icon: Common.Icons.icons.info }
                    ]

                    delegate: MouseArea {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        cursorShape: Qt.PointingHandCursor
                        onClicked: currentSection = modelData.id

                        Rectangle {
                            anchors.fill: parent
                            radius: Common.Appearance.rounding.medium
                            color: currentSection === modelData.id
                                ? Common.Appearance.m3colors.primaryContainer
                                : (parent.containsMouse
                                    ? Common.Appearance.surfaceLayer(2)
                                    : "transparent")
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Common.Appearance.spacing.small
                            anchors.rightMargin: Common.Appearance.spacing.small
                            spacing: Common.Appearance.spacing.small

                            Common.Icon {
                                name: modelData.icon
                                size: Common.Appearance.sizes.iconMedium
                                color: currentSection === modelData.id
                                    ? Common.Appearance.m3colors.onPrimaryContainer
                                    : Common.Appearance.m3colors.onSurface
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                font.family: Common.Appearance.fonts.main
                                font.pixelSize: Common.Appearance.fontSize.normal
                                color: currentSection === modelData.id
                                    ? Common.Appearance.m3colors.onPrimaryContainer
                                    : Common.Appearance.m3colors.onSurface
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Close button
                MouseArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    cursorShape: Qt.PointingHandCursor
                    onClicked: GlobalStates.settingsOpen = false

                    Rectangle {
                        anchors.fill: parent
                        radius: Common.Appearance.rounding.medium
                        color: parent.containsMouse
                            ? Common.Appearance.m3colors.errorContainer
                            : "transparent"
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: Common.Appearance.spacing.small

                        Common.Icon {
                            name: Common.Icons.icons.close
                            size: Common.Appearance.sizes.iconMedium
                            color: Common.Appearance.m3colors.error
                        }

                        Text {
                            text: "Close"
                            font.family: Common.Appearance.fonts.main
                            font.pixelSize: Common.Appearance.fontSize.normal
                            color: Common.Appearance.m3colors.error
                        }
                    }
                }
            }
        }

        // Content area
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentLoader.item ? contentLoader.item.implicitHeight : 0
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            Loader {
                id: contentLoader
                width: parent.width
                sourceComponent: {
                    switch (currentSection) {
                        case "appearance": return appearanceSection
                        case "bar": return barSection
                        case "notifications": return notificationsSection
                        case "shortcuts": return shortcutsSection
                        case "about": return aboutSection
                        default: return appearanceSection
                    }
                }
            }
        }
    }

    property string currentSection: "appearance"

    // Appearance section
    Component {
        id: appearanceSection

        ColumnLayout {
            spacing: Common.Appearance.spacing.large

            SectionHeader { text: "Theme" }

            SettingRow {
                label: "Dark mode"
                description: "Use dark theme colors"

                Switch {
                    checked: Common.Config.darkMode
                    onCheckedChanged: {
                        Common.Config.darkMode = checked
                        Common.Config.save()
                    }
                }
            }

            SettingRow {
                label: "Panel opacity"
                description: "Transparency of panels and sidebars"

                RowLayout {
                    Slider {
                        Layout.preferredWidth: 150
                        from: 0.5
                        to: 1.0
                        value: Common.Config.panelOpacity
                        onValueChanged: {
                            Common.Config.panelOpacity = value
                            Common.Config.save()
                        }
                    }

                    Text {
                        text: Math.round(Common.Config.panelOpacity * 100) + "%"
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.m3colors.onSurfaceVariant
                    }
                }
            }

            SectionHeader { text: "Fonts" }

            SettingRow {
                label: "Font family"
                description: "Main UI font"

                Text {
                    text: Common.Config.fontFamily
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.normal
                    color: Common.Appearance.m3colors.onSurfaceVariant
                }
            }

            SettingRow {
                label: "Font size"
                description: "Base font size"

                RowLayout {
                    Slider {
                        Layout.preferredWidth: 100
                        from: 10
                        to: 18
                        stepSize: 1
                        value: Common.Config.fontSize
                        onValueChanged: {
                            Common.Config.fontSize = value
                            Common.Config.save()
                        }
                    }

                    Text {
                        text: Common.Config.fontSize + "px"
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.m3colors.onSurfaceVariant
                    }
                }
            }
        }
    }

    // Bar section
    Component {
        id: barSection

        ColumnLayout {
            spacing: Common.Appearance.spacing.large

            SectionHeader { text: "Status Bar Items" }

            SettingRow {
                label: "Show weather"
                Switch {
                    checked: Common.Config.showWeather
                    onCheckedChanged: Common.Config.setValue("bar.showWeather", checked)
                }
            }

            SettingRow {
                label: "Show battery"
                Switch {
                    checked: Common.Config.showBattery
                    onCheckedChanged: Common.Config.setValue("bar.showBattery", checked)
                }
            }

            SettingRow {
                label: "Show network"
                Switch {
                    checked: Common.Config.showNetwork
                    onCheckedChanged: Common.Config.setValue("bar.showNetwork", checked)
                }
            }

            SettingRow {
                label: "Show system tray"
                Switch {
                    checked: Common.Config.showTray
                    onCheckedChanged: Common.Config.setValue("bar.showTray", checked)
                }
            }

            SettingRow {
                label: "Show clock"
                Switch {
                    checked: Common.Config.showClock
                    onCheckedChanged: Common.Config.setValue("bar.showClock", checked)
                }
            }
        }
    }

    // Notifications section
    Component {
        id: notificationsSection

        ColumnLayout {
            spacing: Common.Appearance.spacing.large

            SectionHeader { text: "Notification Behavior" }

            SettingRow {
                label: "Notification timeout"
                description: "How long notifications stay visible"

                RowLayout {
                    Slider {
                        Layout.preferredWidth: 150
                        from: 2000
                        to: 10000
                        stepSize: 1000
                        value: Common.Config.notificationTimeout
                        onValueChanged: Common.Config.setValue("notifications.timeout", value)
                    }

                    Text {
                        text: (Common.Config.notificationTimeout / 1000) + "s"
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.m3colors.onSurfaceVariant
                    }
                }
            }

            SettingRow {
                label: "Notification sounds"
                Switch {
                    checked: Common.Config.notificationSounds
                    onCheckedChanged: Common.Config.setValue("notifications.sounds", checked)
                }
            }
        }
    }

    // Shortcuts section
    Component {
        id: shortcutsSection

        ColumnLayout {
            spacing: Common.Appearance.spacing.medium

            SectionHeader { text: "Keyboard Shortcuts" }

            Repeater {
                model: [
                    { key: "Super + Space", action: "Open launcher" },
                    { key: "Super + N", action: "Toggle notifications sidebar" },
                    { key: "Super + A", action: "Toggle app launcher sidebar" },
                    { key: "Super + Escape", action: "Close all panels" },
                    { key: "Volume Keys", action: "Adjust volume" },
                    { key: "Brightness Keys", action: "Adjust brightness" }
                ]

                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: Common.Appearance.spacing.medium

                    Rectangle {
                        Layout.preferredWidth: 140
                        Layout.preferredHeight: 28
                        radius: Common.Appearance.rounding.small
                        color: Common.Appearance.m3colors.surfaceVariant

                        Text {
                            anchors.centerIn: parent
                            text: modelData.key
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.m3colors.onSurfaceVariant
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.action
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.normal
                        color: Common.Appearance.m3colors.onSurface
                    }
                }
            }
        }
    }

    // About section
    Component {
        id: aboutSection

        ColumnLayout {
            spacing: Common.Appearance.spacing.large

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 100

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Common.Appearance.spacing.small

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Hypercube"
                        font.family: Common.Appearance.fonts.title
                        font.pixelSize: Common.Appearance.fontSize.display
                        font.weight: Font.Medium
                        color: Common.Appearance.m3colors.primary
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Quickshell Configuration"
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.normal
                        color: Common.Appearance.m3colors.onSurfaceVariant
                    }
                }
            }

            SectionHeader { text: "System Information" }

            Repeater {
                model: [
                    { label: "Shell", value: "Quickshell" },
                    { label: "Compositor", value: "Hyprland" },
                    { label: "Theme", value: "Material Design 3 + Tokyonight" }
                ]

                delegate: RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: modelData.label
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.normal
                        color: Common.Appearance.m3colors.onSurfaceVariant
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: modelData.value
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.normal
                        color: Common.Appearance.m3colors.onSurface
                    }
                }
            }
        }
    }

    // Helper components
    component SectionHeader: Text {
        Layout.fillWidth: true
        Layout.topMargin: Common.Appearance.spacing.small
        font.family: Common.Appearance.fonts.main
        font.pixelSize: Common.Appearance.fontSize.small
        font.weight: Font.Medium
        color: Common.Appearance.m3colors.primary
        textFormat: Text.PlainText
    }

    component SettingRow: RowLayout {
        property string label: ""
        property string description: ""
        default property alias content: contentItem.data

        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: label
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.normal
                color: Common.Appearance.m3colors.onSurface
            }

            Text {
                visible: description !== ""
                text: description
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.m3colors.onSurfaceVariant
            }
        }

        Item {
            id: contentItem
            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: childrenRect.height
        }
    }
}
