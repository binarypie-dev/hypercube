import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

import "../common" as Common
import "../../" as Root
import "../../services" as Services

// System updates and setup view for the left sidebar
ColumnLayout {
    id: root
    spacing: Common.Appearance.spacing.large

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.small

        Text {
            Layout.fillWidth: true
            text: "System Setup"
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

            onClicked: Root.GlobalStates.sidebarLeftOpen = false

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

    // Network warning (if no network and preinstall not done)
    Rectangle {
        visible: !Services.Network.connected && !Services.Updates.preinstallCompleted
        Layout.fillWidth: true
        Layout.preferredHeight: networkWarningContent.implicitHeight + Common.Appearance.spacing.medium * 2
        radius: Common.Appearance.rounding.large
        color: Common.Appearance.m3colors.errorContainer

        RowLayout {
            id: networkWarningContent
            anchors.fill: parent
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            Common.Icon {
                name: Common.Icons.icons.wifiOff
                size: Common.Appearance.sizes.iconLarge
                color: Common.Appearance.m3colors.onErrorContainer
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "No Network Connection"
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.normal
                    font.weight: Font.Medium
                    color: Common.Appearance.m3colors.onErrorContainer
                }

                Text {
                    Layout.fillWidth: true
                    text: "Connect to the internet to install default applications."
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.small
                    color: Common.Appearance.m3colors.onErrorContainer
                    wrapMode: Text.WordWrap
                    opacity: 0.8
                }
            }
        }
    }

    // Flatpak Preinstall Card
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: preinstallContent.implicitHeight + Common.Appearance.spacing.medium * 2
        radius: Common.Appearance.rounding.large
        color: Common.Appearance.m3colors.surfaceVariant

        ColumnLayout {
            id: preinstallContent
            anchors.fill: parent
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            // Header row
            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.medium

                Common.Icon {
                    name: Services.Updates.preinstallCompleted
                        ? Common.Icons.icons.checkCircle
                        : Common.Icons.icons.download
                    size: Common.Appearance.sizes.iconLarge
                    color: Services.Updates.preinstallCompleted
                        ? Common.Appearance.m3colors.primary
                        : Common.Appearance.m3colors.onSurfaceVariant
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Default Applications"
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.normal
                        font.weight: Font.Medium
                        color: Common.Appearance.m3colors.onSurface
                    }

                    Text {
                        text: Services.Updates.preinstallCompleted
                            ? "Installed"
                            : (Services.Updates.preinstallRunning
                                ? Services.Updates.preinstallStatus
                                : Services.Updates.preinstallTotal + " apps ready to install")
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.m3colors.onSurfaceVariant
                    }
                }
            }

            // Progress bar (when running)
            Rectangle {
                visible: Services.Updates.preinstallRunning
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                radius: 2
                color: Common.Appearance.m3colors.surfaceVariant
                border.width: 1
                border.color: Common.Appearance.m3colors.outline

                Rectangle {
                    width: parent.width * (Services.Updates.preinstallProgress() / 100)
                    height: parent.height
                    radius: 2
                    color: Common.Appearance.m3colors.primary

                    Behavior on width {
                        NumberAnimation { duration: 200 }
                    }
                }
            }

            // Action button
            MouseArea {
                visible: !Services.Updates.preinstallRunning
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                enabled: Services.Network.connected || Services.Updates.preinstallCompleted

                onClicked: {
                    if (Services.Updates.preinstallCompleted) {
                        // Reset and allow re-running
                        Services.Updates.resetPreinstall()
                    } else {
                        Services.Updates.runPreinstall()
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Common.Appearance.rounding.medium
                    color: parent.containsMouse
                        ? Common.Appearance.m3colors.primary
                        : Common.Appearance.m3colors.primaryContainer
                    opacity: parent.enabled ? 1 : 0.5
                }

                Text {
                    anchors.centerIn: parent
                    text: Services.Updates.preinstallCompleted
                        ? "Reinstall Default Apps"
                        : "Install Now"
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.normal
                    font.weight: Font.Medium
                    color: parent.containsMouse
                        ? Common.Appearance.m3colors.onPrimary
                        : Common.Appearance.m3colors.onPrimaryContainer
                }
            }

            // Log output (when running or just completed)
            Rectangle {
                visible: Services.Updates.preinstallRunning || (Services.Updates.preinstallLog.length > 0 && !Services.Updates.preinstallCompleted)
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                radius: Common.Appearance.rounding.small
                color: Common.Appearance.m3colors.surface
                clip: true

                ListView {
                    id: logView
                    anchors.fill: parent
                    anchors.margins: Common.Appearance.spacing.small
                    model: Services.Updates.preinstallLog
                    spacing: 2

                    delegate: Text {
                        required property string modelData
                        width: logView.width
                        text: modelData
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.smallest
                        color: Common.Appearance.m3colors.onSurfaceVariant
                        wrapMode: Text.WrapAnywhere
                    }

                    onCountChanged: {
                        positionViewAtEnd()
                    }
                }
            }
        }
    }

    // System Updates Card
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: updatesContent.implicitHeight + Common.Appearance.spacing.medium * 2
        radius: Common.Appearance.rounding.large
        color: Common.Appearance.m3colors.surfaceVariant

        ColumnLayout {
            id: updatesContent
            anchors.fill: parent
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.medium

                Common.Icon {
                    name: Services.Updates.updateCount > 0
                        ? Common.Icons.icons.update
                        : Common.Icons.icons.checkCircle
                    size: Common.Appearance.sizes.iconLarge
                    color: Services.Updates.updateCount > 0
                        ? Common.Appearance.m3colors.primary
                        : Common.Appearance.m3colors.onSurfaceVariant
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "System Updates"
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.normal
                        font.weight: Font.Medium
                        color: Common.Appearance.m3colors.onSurface
                    }

                    Text {
                        text: Services.Updates.summary()
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.small
                        color: Common.Appearance.m3colors.onSurfaceVariant
                    }
                }

                // Refresh button
                MouseArea {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    enabled: !Services.Updates.checking

                    onClicked: Services.Updates.checkUpdates()

                    Rectangle {
                        anchors.fill: parent
                        radius: Common.Appearance.rounding.small
                        color: parent.containsMouse ? Common.Appearance.m3colors.surface : "transparent"
                    }

                    Common.Icon {
                        anchors.centerIn: parent
                        name: Common.Icons.icons.refresh
                        size: Common.Appearance.sizes.iconSmall
                        color: Common.Appearance.m3colors.onSurfaceVariant
                        opacity: Services.Updates.checking ? 0.5 : 1

                        RotationAnimation on rotation {
                            running: Services.Updates.checking
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                        }
                    }
                }
            }

            // Last checked
            Text {
                visible: Services.Updates.lastChecked !== ""
                text: "Last checked: " + Services.Updates.lastChecked
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.smallest
                color: Common.Appearance.m3colors.onSurfaceVariant
                opacity: 0.7
            }
        }
    }

    // Spacer
    Item { Layout.fillHeight: true }

    // Auto-run preinstall when network becomes available
    Connections {
        target: Services.Network
        function onConnectedChanged() {
            if (Services.Network.connected && !Services.Updates.preinstallCompleted && !Services.Updates.preinstallRunning) {
                // Small delay to let network settle
                autoInstallTimer.start()
            }
        }
    }

    Timer {
        id: autoInstallTimer
        interval: 2000
        onTriggered: {
            if (Services.Network.connected && !Services.Updates.preinstallCompleted && !Services.Updates.preinstallRunning) {
                Services.Updates.runPreinstall()
            }
        }
    }
}
