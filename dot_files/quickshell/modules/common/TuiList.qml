import QtQuick
import QtQuick.Layouts

// TUI-style list container with optional section headers
Rectangle {
    id: root

    property string header: ""
    property alias model: repeater.model
    property alias delegate: repeater.delegate
    property alias count: repeater.count
    property string emptyText: "-- No items --"
    property bool showBorder: true
    property bool showSeparators: true

    default property alias content: contentColumn.data

    implicitWidth: 200
    implicitHeight: contentColumn.implicitHeight + (header !== "" ? headerItem.height : 0)

    color: "transparent"
    border.width: showBorder ? Appearance.borderWidth.thin : 0
    border.color: Appearance.colors.border
    radius: showBorder ? Appearance.rounding.tiny : 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Section header
        Rectangle {
            id: headerItem
            Layout.fillWidth: true
            Layout.preferredHeight: root.header !== "" ? 24 : 0
            visible: root.header !== ""
            color: Appearance.colors.bgHighlight
            radius: showBorder ? Appearance.rounding.tiny : 0

            // Mask bottom corners
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.radius
                color: parent.color
            }

            // Bottom border
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Appearance.colors.border
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Appearance.spacing.medium
                anchors.verticalCenter: parent.verticalCenter
                text: root.header
                font.family: Appearance.fonts.mono
                font.pixelSize: Appearance.fontSize.small
                font.bold: true
                color: Appearance.colors.fgDark
            }
        }

        // Content area
        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: showBorder ? Appearance.spacing.small : 0
            spacing: 0

            Repeater {
                id: repeater
            }

            // Empty state
            Text {
                visible: repeater.count === 0 && root.emptyText !== ""
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.emptyText
                font.family: Appearance.fonts.mono
                font.pixelSize: Appearance.fontSize.small
                color: Appearance.colors.comment
            }
        }
    }
}
