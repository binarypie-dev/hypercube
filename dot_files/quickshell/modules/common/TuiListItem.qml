import QtQuick
import QtQuick.Layouts

// TUI-style list item with icon, label, status, and actions
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string sublabel: ""
    property string status: ""  // e.g., "[Connected]", "[ON]"
    property color statusColor: Appearance.colors.fgDark
    property bool selected: false
    property bool showSeparator: true
    property bool enabled: true

    signal clicked()
    signal doubleClicked()

    default property alias actions: actionsRow.data

    implicitWidth: parent ? parent.width : 200
    implicitHeight: 28

    color: {
        if (selected) return Appearance.colors.bgVisual
        if (mouseArea.containsMouse && enabled) return Appearance.colors.bgHighlight
        return "transparent"
    }

    opacity: enabled ? 1.0 : 0.5

    // Bottom separator
    Rectangle {
        visible: root.showSeparator
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Appearance.spacing.medium
        anchors.rightMargin: Appearance.spacing.medium
        height: 1
        color: Appearance.colors.fgGutter
        opacity: 0.3
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.spacing.medium
        anchors.rightMargin: Appearance.spacing.medium
        spacing: Appearance.spacing.medium

        // Icon
        Text {
            visible: root.icon !== ""
            text: root.icon
            font.family: Appearance.fonts.mono
            font.pixelSize: Appearance.fontSize.normal
            color: root.selected ? Appearance.colors.blue : Appearance.colors.fgDark
        }

        // Labels
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.label
                font.family: Appearance.fonts.mono
                font.pixelSize: Appearance.fontSize.normal
                color: Appearance.colors.fg
                elide: Text.ElideRight
            }

            Text {
                visible: root.sublabel !== ""
                Layout.fillWidth: true
                text: root.sublabel
                font.family: Appearance.fonts.mono
                font.pixelSize: Appearance.fontSize.small
                color: Appearance.colors.comment
                elide: Text.ElideRight
            }
        }

        // Status
        Text {
            visible: root.status !== ""
            text: root.status
            font.family: Appearance.fonts.mono
            font.pixelSize: Appearance.fontSize.small
            font.bold: true
            color: root.statusColor
        }

        // Actions slot
        Row {
            id: actionsRow
            spacing: Appearance.spacing.small
            visible: children.length > 0
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
        onDoubleClicked: root.doubleClicked()
    }
}
