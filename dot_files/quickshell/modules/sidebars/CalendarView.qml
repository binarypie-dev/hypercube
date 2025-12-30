import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import "../common" as Common
import "../../services" as Services
import "../../" as Root

// Calendar view for the right sidebar
Flickable {
    id: root
    contentHeight: contentColumn.height
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

    ColumnLayout {
        id: contentColumn
        width: parent.width
        spacing: Common.Appearance.spacing.large

        // Header with close button
        RowLayout {
            Layout.fillWidth: true
            spacing: Common.Appearance.spacing.small

            Text {
                Layout.fillWidth: true
                text: "Calendar"
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

        // Calendar card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: calendarContent.implicitHeight + Common.Appearance.spacing.medium * 2
            radius: Common.Appearance.rounding.large
            color: Common.Appearance.m3colors.surfaceVariant

            ColumnLayout {
                id: calendarContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Common.Appearance.spacing.medium
                spacing: Common.Appearance.spacing.small

                property int displayMonth: new Date().getMonth()
                property int displayYear: new Date().getFullYear()

                // Month navigation
                RowLayout {
                    Layout.fillWidth: true

                    MouseArea {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            if (calendarContent.displayMonth === 0) {
                                calendarContent.displayMonth = 11
                                calendarContent.displayYear--
                            } else {
                                calendarContent.displayMonth--
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Common.Appearance.rounding.small
                            color: parent.containsMouse ? Common.Appearance.m3colors.surface : "transparent"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Common.Icons.icons.back
                            font.family: Common.Appearance.fonts.icon
                            font.pixelSize: Common.Appearance.sizes.iconMedium
                            color: Common.Appearance.m3colors.onSurface
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: {
                            var months = Services.DateTime.monthNames
                            if (months && months.length > calendarContent.displayMonth) {
                                return months[calendarContent.displayMonth] + " " + calendarContent.displayYear
                            }
                            return calendarContent.displayYear.toString()
                        }
                        font.family: Common.Appearance.fonts.main
                        font.pixelSize: Common.Appearance.fontSize.normal
                        font.weight: Font.Medium
                        color: Common.Appearance.m3colors.onSurface
                    }

                    MouseArea {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            if (calendarContent.displayMonth === 11) {
                                calendarContent.displayMonth = 0
                                calendarContent.displayYear++
                            } else {
                                calendarContent.displayMonth++
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Common.Appearance.rounding.small
                            color: parent.containsMouse ? Common.Appearance.m3colors.surface : "transparent"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Common.Icons.icons.forward
                            font.family: Common.Appearance.fonts.icon
                            font.pixelSize: Common.Appearance.sizes.iconMedium
                            color: Common.Appearance.m3colors.onSurface
                        }
                    }
                }

                // Day headers
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Repeater {
                        model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            font.family: Common.Appearance.fonts.main
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.m3colors.onSurfaceVariant
                        }
                    }
                }

                // Calendar grid
                Grid {
                    id: calendarGrid
                    Layout.fillWidth: true
                    columns: 7
                    spacing: 2

                    Repeater {
                        model: 42

                        Rectangle {
                            width: Math.max((calendarGrid.width - 12) / 7, 20)
                            height: width
                            radius: width / 2

                            property int dayNumber: {
                                var firstDay = new Date(calendarContent.displayYear, calendarContent.displayMonth, 1).getDay()
                                var daysInMonth = new Date(calendarContent.displayYear, calendarContent.displayMonth + 1, 0).getDate()
                                var dayIndex = index - firstDay + 1

                                if (dayIndex < 1 || dayIndex > daysInMonth) {
                                    return 0
                                }
                                return dayIndex
                            }

                            property bool isToday: {
                                var now = new Date()
                                return dayNumber === now.getDate() &&
                                       calendarContent.displayMonth === now.getMonth() &&
                                       calendarContent.displayYear === now.getFullYear()
                            }

                            color: isToday
                                ? Common.Appearance.m3colors.primary
                                : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: dayNumber > 0 ? dayNumber : ""
                                font.family: Common.Appearance.fonts.main
                                font.pixelSize: Common.Appearance.fontSize.small
                                color: isToday
                                    ? Common.Appearance.m3colors.onPrimary
                                    : Common.Appearance.m3colors.onSurface
                            }
                        }
                    }
                }
            }
        }

        // Spacer
        Item { Layout.fillHeight: true }
    }
}
