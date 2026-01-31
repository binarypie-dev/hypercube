import QtQuick
import QtQuick.Controls

// TUI-style single-line input
Rectangle {
    id: root

    property alias text: textInput.text
    property alias placeholderText: placeholder.text
    property bool password: false
    property bool enabled: true

    signal accepted()

    function clear() {
        textInput.clear()
    }

    function focusInput() {
        textInput.forceActiveFocus()
    }

    implicitWidth: 200
    implicitHeight: 28

    color: Appearance.colors.bgDark
    border.width: Appearance.borderWidth.thin
    border.color: Appearance.colors.border
    radius: Appearance.rounding.tiny

    opacity: enabled ? 1.0 : 0.5

    TextInput {
        id: textInput
        anchors.fill: parent
        anchors.leftMargin: Appearance.spacing.medium
        anchors.rightMargin: Appearance.spacing.medium
        verticalAlignment: TextInput.AlignVCenter

        font.family: Appearance.fonts.mono
        font.pixelSize: Appearance.fontSize.normal
        color: Appearance.colors.fg
        selectionColor: Appearance.colors.bgVisual
        selectedTextColor: Appearance.colors.fg

        echoMode: root.password ? TextInput.Password : TextInput.Normal
        enabled: root.enabled
        clip: true

        Keys.forwardTo: [root]

        onAccepted: root.accepted()
    }

    Text {
        id: placeholder
        anchors.fill: textInput
        anchors.leftMargin: Appearance.spacing.medium
        verticalAlignment: Text.AlignVCenter

        font.family: Appearance.fonts.mono
        font.pixelSize: Appearance.fontSize.normal
        color: Appearance.colors.comment

        visible: textInput.text === "" && !textInput.activeFocus
    }
}
