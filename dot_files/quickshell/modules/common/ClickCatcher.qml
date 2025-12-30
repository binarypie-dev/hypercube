import QtQuick
import Quickshell
import Quickshell.Wayland

// Fullscreen transparent overlay that catches clicks outside panels
// Used to implement click-outside-to-close behavior
PanelWindow {
    id: root

    required property var targetScreen
    screen: targetScreen

    // Fill the entire screen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    // Must be below the actual panels in the layer stack
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "clickcatcher"

    // Signal emitted when the catcher is clicked
    signal clicked()

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
