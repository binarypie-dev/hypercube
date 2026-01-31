import QtQuick
import QtQuick.Layouts

// TUI-style card container with optional title bar
Rectangle {
    id: root

    property string title: ""
    property bool showBorder: true
    property int contentPadding: Appearance.spacing.medium

    default property alias content: contentContainer.children

    implicitWidth: 200
    implicitHeight: titleBar.height + contentContainer.childrenRect.height + (contentPadding * 2)

    color: Appearance.colors.bgDark
    border.width: showBorder ? Appearance.borderWidth.thin : 0
    border.color: Appearance.colors.border
    radius: Appearance.rounding.tiny

    // Title bar
    Rectangle {
        id: titleBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.title !== "" ? 24 : 0
        visible: root.title !== ""
        color: Appearance.colors.bgHighlight
        radius: Appearance.rounding.tiny

        // Mask bottom corners
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.radius
            color: parent.color
            visible: parent.visible
        }

        // Bottom border
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Appearance.colors.border
            visible: parent.visible
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: Appearance.spacing.medium
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            font.family: Appearance.fonts.mono
            font.pixelSize: Appearance.fontSize.small
            font.bold: true
            color: Appearance.colors.fg
        }
    }

    // Content area - use Item with explicit positioning
    Item {
        id: contentContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: titleBar.bottom
        anchors.margins: root.contentPadding
        height: childrenRect.height
    }
}
