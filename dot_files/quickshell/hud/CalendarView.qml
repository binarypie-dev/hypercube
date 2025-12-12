import QtQuick
import QtQuick.Layouts

Rectangle {
    id: calendarView
    width: parent.width
    height: visible ? calendarContent.implicitHeight : 0
    color: "transparent"
    clip: true

    required property bool isVisible
    visible: isVisible

    property int calendarMonth: new Date().getMonth()
    property int calendarYear: new Date().getFullYear()

    Behavior on height {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
    }

    function reset() {
        var now = new Date();
        calendarMonth = now.getMonth();
        calendarYear = now.getFullYear();
    }

    Column {
        id: calendarContent
        width: parent.width
        spacing: 8

        // Month/Year header with navigation
        Rectangle {
            width: parent.width
            height: 36
            radius: 6
            color: "#24283b"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8

                // Previous month
                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 4
                    color: prevMonthMouse.containsMouse ? "#33467c" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "<"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#c0caf5"
                    }

                    MouseArea {
                        id: prevMonthMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (calendarView.calendarMonth === 0) {
                                calendarView.calendarMonth = 11;
                                calendarView.calendarYear--;
                            } else {
                                calendarView.calendarMonth--;
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Month Year display
                Text {
                    text: new Date(calendarView.calendarYear, calendarView.calendarMonth, 1).toLocaleDateString(Qt.locale(), "MMMM yyyy")
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    font.bold: true
                    color: "#c0caf5"
                }

                Item { Layout.fillWidth: true }

                // Next month
                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 4
                    color: nextMonthMouse.containsMouse ? "#33467c" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: ">"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#c0caf5"
                    }

                    MouseArea {
                        id: nextMonthMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (calendarView.calendarMonth === 11) {
                                calendarView.calendarMonth = 0;
                                calendarView.calendarYear++;
                            } else {
                                calendarView.calendarMonth++;
                            }
                        }
                    }
                }
            }
        }

        // Day headers
        Row {
            width: parent.width

            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                delegate: Item {
                    width: parent.width / 7
                    height: 24

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                        color: "#565f89"
                    }
                }
            }
        }

        // Calendar grid
        Grid {
            id: calendarGrid
            width: parent.width
            columns: 7

            property var firstDay: new Date(calendarView.calendarYear, calendarView.calendarMonth, 1)
            property int startDay: firstDay.getDay()
            property int daysInMonth: new Date(calendarView.calendarYear, calendarView.calendarMonth + 1, 0).getDate()
            property var today: new Date()

            Repeater {
                model: 42

                delegate: Item {
                    width: calendarGrid.width / 7
                    height: 32

                    property int dayNum: index - calendarGrid.startDay + 1
                    property bool isCurrentMonth: dayNum > 0 && dayNum <= calendarGrid.daysInMonth
                    property bool isToday: isCurrentMonth &&
                        dayNum === calendarGrid.today.getDate() &&
                        calendarView.calendarMonth === calendarGrid.today.getMonth() &&
                        calendarView.calendarYear === calendarGrid.today.getFullYear()

                    Rectangle {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        radius: 14
                        color: isToday ? "#7aa2f7" : "transparent"
                        visible: isCurrentMonth

                        Text {
                            anchors.centerIn: parent
                            text: isCurrentMonth ? dayNum : ""
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                            color: isToday ? "#1a1b26" : "#c0caf5"
                        }
                    }
                }
            }
        }
    }
}
