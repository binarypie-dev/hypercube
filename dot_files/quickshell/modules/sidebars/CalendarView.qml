import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import "../common" as Common
import "../../services" as Services
import "../../" as Root

// Calendar view - TUI style
Flickable {
    id: root
    contentHeight: contentColumn.height + 10
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    topMargin: 5
    bottomMargin: 5

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        width: 6

        contentItem: Rectangle {
            implicitWidth: 4
            radius: 2
            color: Common.Appearance.colors.bgVisual
        }
    }

    property int displayMonth: new Date().getMonth()
    property int displayYear: new Date().getFullYear()

    ColumnLayout {
        id: contentColumn
        width: parent.width
        spacing: Common.Appearance.spacing.medium

        // Header
        Text {
            Layout.fillWidth: true
            text: "Calendar"
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.large
            font.bold: true
            color: Common.Appearance.colors.fg
        }

        // Current date and time display
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: timeContent.height + Common.Appearance.spacing.medium * 2
            color: Common.Appearance.colors.bgDark
            border.width: 1
            border.color: Common.Appearance.colors.border
            radius: Common.Appearance.rounding.tiny

            ColumnLayout {
                id: timeContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Common.Appearance.spacing.medium
                spacing: Common.Appearance.spacing.tiny

                Text {
                    Layout.fillWidth: true
                    text: Services.DateTime.timeString
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.display
                    font.bold: true
                    color: Common.Appearance.colors.cyan
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: Services.DateTime.dayNames[Services.DateTime.dayOfWeek] + ", " +
                          Services.DateTime.monthNames[Services.DateTime.month - 1] + " " +
                          Services.DateTime.day + ", " + Services.DateTime.year
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.normal
                    color: Common.Appearance.colors.fgDark
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Calendar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: calendarContent.height + Common.Appearance.spacing.medium * 2
            color: Common.Appearance.colors.bgDark
            border.width: 1
            border.color: Common.Appearance.colors.border
            radius: Common.Appearance.rounding.tiny

            ColumnLayout {
                id: calendarContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Common.Appearance.spacing.medium
                spacing: Common.Appearance.spacing.small

                // Month navigation
                RowLayout {
                    Layout.fillWidth: true

                    Common.TuiButton {
                        icon: Common.Icons.icons.back
                        onClicked: {
                            if (root.displayMonth === 0) {
                                root.displayMonth = 11
                                root.displayYear--
                            } else {
                                root.displayMonth--
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: {
                            var months = Services.DateTime.monthNames
                            if (months && months.length > root.displayMonth) {
                                return months[root.displayMonth] + " " + root.displayYear
                            }
                            return root.displayYear.toString()
                        }
                        font.family: Common.Appearance.fonts.mono
                        font.pixelSize: Common.Appearance.fontSize.normal
                        font.bold: true
                        color: Common.Appearance.colors.fg
                    }

                    Common.TuiButton {
                        icon: Common.Icons.icons.forward
                        onClicked: {
                            if (root.displayMonth === 11) {
                                root.displayMonth = 0
                                root.displayYear++
                            } else {
                                root.displayMonth++
                            }
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
                            font.family: Common.Appearance.fonts.mono
                            font.pixelSize: Common.Appearance.fontSize.small
                            color: Common.Appearance.colors.comment
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
                            radius: Common.Appearance.rounding.tiny

                            property int dayNumber: {
                                var firstDay = new Date(root.displayYear, root.displayMonth, 1).getDay()
                                var daysInMonth = new Date(root.displayYear, root.displayMonth + 1, 0).getDate()
                                var dayIndex = index - firstDay + 1

                                if (dayIndex < 1 || dayIndex > daysInMonth) {
                                    return 0
                                }
                                return dayIndex
                            }

                            property bool isToday: {
                                var now = new Date()
                                return dayNumber === now.getDate() &&
                                       root.displayMonth === now.getMonth() &&
                                       root.displayYear === now.getFullYear()
                            }

                            color: isToday
                                ? Common.Appearance.colors.bgVisual
                                : "transparent"

                            border.width: isToday ? 1 : 0
                            border.color: Common.Appearance.colors.blue

                            Text {
                                anchors.centerIn: parent
                                text: dayNumber > 0 ? dayNumber : ""
                                font.family: Common.Appearance.fonts.mono
                                font.pixelSize: Common.Appearance.fontSize.small
                                font.bold: isToday
                                color: isToday
                                    ? Common.Appearance.colors.blue
                                    : Common.Appearance.colors.fg
                            }
                        }
                    }
                }
            }
        }

        // Spacer
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Common.Appearance.spacing.medium
        }
    }
}
