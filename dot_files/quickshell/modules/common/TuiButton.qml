import QtQuick
import QtQuick.Layouts

// TUI-style button with thin border
Rectangle {
    id: root

    property string text: ""
    property string icon: ""  // Icon name from Icons.qml
    property int iconSize: 14
    property bool danger: false
    property bool enabled: true
    property bool primary: false

    signal clicked()

    implicitWidth: Math.max(contentRow.implicitWidth + Appearance.spacing.medium * 2, 60)
    implicitHeight: 28

    color: {
        if (!enabled) return "transparent"
        if (mouseArea.containsPress) return Appearance.colors.bgVisual
        if (mouseArea.containsMouse) {
            return danger ? Qt.rgba(Appearance.colors.red.r, Appearance.colors.red.g, Appearance.colors.red.b, 0.2)
                          : Appearance.colors.bgHighlight
        }
        return "transparent"
    }

    border.width: Appearance.borderWidth.thin
    border.color: {
        if (!enabled) return Appearance.colors.fgGutter
        if (danger && mouseArea.containsMouse) return Appearance.colors.red
        if (primary) return Appearance.colors.blue
        return Appearance.colors.border
    }

    radius: Appearance.rounding.tiny

    opacity: enabled ? 1.0 : 0.5

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        Icon {
            visible: root.icon !== ""
            name: root.icon
            size: root.iconSize
            color: {
                if (!root.enabled) return Appearance.colors.fgGutter
                if (root.danger) return Appearance.colors.red
                if (root.primary) return Appearance.colors.blue
                return Appearance.colors.fg
            }
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: root.text !== ""
            text: root.text
            font.family: Appearance.fonts.mono
            font.pixelSize: Appearance.fontSize.small
            font.bold: root.primary
            color: {
                if (!root.enabled) return Appearance.colors.fgGutter
                if (root.danger) return Appearance.colors.red
                if (root.primary) return Appearance.colors.blue
                return Appearance.colors.fg
            }
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
