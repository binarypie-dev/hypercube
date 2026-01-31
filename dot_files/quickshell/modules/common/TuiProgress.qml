import QtQuick

// TUI-style progress bar with percentage display
Item {
    id: root

    property real value: 0.5  // 0.0 to 1.0
    property bool showValue: true
    property bool useThresholds: false  // Enable color thresholds for battery-like display
    property int lowThreshold: 20
    property int mediumThreshold: 50
    property color normalColor: Appearance.colors.blue
    property color lowColor: Appearance.colors.red
    property color mediumColor: Appearance.colors.yellow
    property bool asciiStyle: false  // Use ASCII blocks instead of filled bar

    implicitWidth: 200
    implicitHeight: 16

    readonly property color activeColor: {
        if (!useThresholds) return normalColor
        const percent = Math.round(value * 100)
        if (percent <= lowThreshold) return lowColor
        if (percent <= mediumThreshold) return mediumColor
        return normalColor
    }

    Row {
        anchors.fill: parent
        spacing: Appearance.spacing.small

        // Progress bar
        Rectangle {
            id: track
            width: parent.width - (showValue ? valueText.width + Appearance.spacing.small : 0)
            height: parent.height
            anchors.verticalCenter: parent.verticalCenter

            color: "transparent"
            border.width: Appearance.borderWidth.thin
            border.color: Appearance.colors.border
            radius: Appearance.rounding.tiny

            // Filled portion (standard style)
            Rectangle {
                visible: !root.asciiStyle
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 2
                width: Math.max(0, (parent.width - 4) * root.value)
                color: root.activeColor
                radius: Appearance.rounding.tiny
            }

            // ASCII style blocks
            Text {
                visible: root.asciiStyle
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter

                readonly property int totalBlocks: 10
                readonly property int filledBlocks: Math.round(root.value * totalBlocks)
                readonly property string filled: "█".repeat(filledBlocks)
                readonly property string empty: "░".repeat(totalBlocks - filledBlocks)

                text: filled + empty
                font.family: Appearance.fonts.mono
                font.pixelSize: Appearance.fontSize.small
                font.letterSpacing: 1
                color: root.activeColor
            }
        }

        // Value display
        Text {
            id: valueText
            visible: root.showValue
            width: 40
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight

            text: Math.round(root.value * 100) + "%"
            font.family: Appearance.fonts.mono
            font.pixelSize: Appearance.fontSize.small
            font.bold: true
            color: root.activeColor
        }
    }
}
