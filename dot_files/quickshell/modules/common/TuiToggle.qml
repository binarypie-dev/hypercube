import QtQuick
import QtQuick.Layouts

// TUI-style toggle switch with text indicator
Rectangle {
    id: root

    property bool checked: false
    property bool enabled: true

    signal toggled()

    implicitWidth: 48
    implicitHeight: 20

    color: "transparent"
    border.width: Appearance.borderWidth.thin
    border.color: checked ? Appearance.colors.cyan : Appearance.colors.border
    radius: Appearance.rounding.tiny

    opacity: enabled ? 1.0 : 0.5

    Text {
        anchors.centerIn: parent
        text: checked ? "[ON]" : "[OFF]"
        font.family: Appearance.fonts.mono
        font.pixelSize: Appearance.fontSize.small
        font.bold: true
        color: checked ? Appearance.colors.cyan : Appearance.colors.fgDark
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            root.checked = !root.checked
            root.toggled()
        }
    }
}
