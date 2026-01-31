import QtQuick

// TUI-style slider with value display
Item {
    id: root

    property real value: 0.5  // 0.0 to 1.0
    property real from: 0.0
    property real to: 1.0
    property bool enabled: true
    property bool showValue: true
    property string valueFormat: "%1%"  // Format string for value display
    property color accentColor: Appearance.colors.blue

    signal moved(real newValue)

    implicitWidth: 200
    implicitHeight: 20

    opacity: enabled ? 1.0 : 0.5

    Row {
        anchors.fill: parent
        spacing: Appearance.spacing.small

        // Track
        Rectangle {
            id: track
            width: parent.width - (showValue ? valueText.width + Appearance.spacing.small : 0)
            height: 12
            anchors.verticalCenter: parent.verticalCenter

            color: "transparent"
            border.width: Appearance.borderWidth.thin
            border.color: Appearance.colors.border
            radius: Appearance.rounding.tiny

            // Filled portion
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 2
                width: Math.max(0, (parent.width - 4) * normalizedValue)
                color: root.accentColor
                radius: Appearance.rounding.tiny
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.enabled
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                onPressed: function(mouse) {
                    updateValue(mouse.x)
                }

                onPositionChanged: function(mouse) {
                    if (pressed) {
                        updateValue(mouse.x)
                    }
                }

                function updateValue(x) {
                    const normalized = Math.max(0, Math.min(1, x / track.width))
                    root.value = root.from + normalized * (root.to - root.from)
                    root.moved(root.value)
                }
            }
        }

        // Value display
        Text {
            id: valueText
            visible: root.showValue
            width: 48
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight

            text: "[" + root.valueFormat.arg(Math.round(normalizedValue * 100)) + "]"
            font.family: Appearance.fonts.mono
            font.pixelSize: Appearance.fontSize.small
            color: Appearance.colors.fgDark
        }
    }

    readonly property real normalizedValue: (value - from) / (to - from)
}
