import QtQuick
import QtQuick.Effects

Item {
    id: root

    property string name: ""
    property color color: "white"
    property int size: 24

    width: size
    height: size

    Image {
        id: iconImage
        anchors.fill: parent
        source: name ? Qt.resolvedUrl("../../assets/icons/" + name + ".svg") : ""
        sourceSize: Qt.size(root.size, root.size)
        fillMode: Image.PreserveAspectFit
        visible: false
        cache: true
    }

    MultiEffect {
        anchors.fill: parent
        source: iconImage
        colorization: 1.0
        colorizationColor: root.color
        visible: iconImage.status === Image.Ready
    }
}
