import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io

Rectangle {
    id: bluetoothView
    width: parent.width
    height: visible ? Math.min(bluetoothContent.implicitHeight, 400) : 0
    color: "transparent"
    clip: true

    required property bool isVisible
    visible: isVisible

    property bool btPowered: false
    property bool btScanning: false
    property var btDevices: []

    Behavior on height {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
    }

    // Refresh bluetooth status when view becomes visible
    onVisibleChanged: {
        if (visible) {
            btStatusProcess.running = true;
            btDevicesProcess.running = true;
        }
    }

    // Get bluetooth power status
    Process {
        id: btStatusProcess
        command: ["bluetoothctl", "show"]
        stdout: SplitParser {
            onRead: (line) => {
                if (line.includes("Powered:")) {
                    bluetoothView.btPowered = line.includes("yes");
                }
                if (line.includes("Discovering:")) {
                    bluetoothView.btScanning = line.includes("yes");
                }
            }
        }
    }

    // Get paired/known devices
    Process {
        id: btDevicesProcess
        command: ["bluetoothctl", "devices"]
        property string output: ""
        stdout: SplitParser {
            onRead: (line) => {
                btDevicesProcess.output += line + "\n";
            }
        }
        onRunningChanged: {
            if (!running && output !== "") {
                var devices = [];
                var lines = output.trim().split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var match = lines[i].match(/Device ([0-9A-F:]+) (.+)/);
                    if (match) {
                        devices.push({
                            address: match[1],
                            name: match[2],
                            connected: false,
                            paired: false
                        });
                    }
                }
                // Now get info for each device
                if (devices.length > 0) {
                    bluetoothView.btDevices = devices;
                    btInfoProcess.deviceIndex = 0;
                    btInfoProcess.runNextDevice();
                } else {
                    bluetoothView.btDevices = [];
                }
                output = "";
            }
        }
    }

    // Get detailed info for each device
    Process {
        id: btInfoProcess
        property int deviceIndex: 0
        property string currentOutput: ""

        function runNextDevice() {
            if (deviceIndex < bluetoothView.btDevices.length) {
                currentOutput = "";
                command = ["bluetoothctl", "info", bluetoothView.btDevices[deviceIndex].address];
                running = true;
            }
        }

        stdout: SplitParser {
            onRead: (line) => {
                btInfoProcess.currentOutput += line + "\n";
            }
        }

        onRunningChanged: {
            if (!running && currentOutput !== "") {
                var devices = bluetoothView.btDevices.slice();
                var dev = devices[deviceIndex];
                if (currentOutput.includes("Connected: yes")) {
                    dev.connected = true;
                }
                if (currentOutput.includes("Paired: yes")) {
                    dev.paired = true;
                }
                if (currentOutput.includes("Icon:")) {
                    var iconMatch = currentOutput.match(/Icon: (.+)/);
                    if (iconMatch) dev.icon = iconMatch[1].trim();
                }
                devices[deviceIndex] = dev;
                bluetoothView.btDevices = devices;

                deviceIndex++;
                runNextDevice();
            }
        }
    }

    // Power on/off
    Process {
        id: btPowerProcess
        property bool targetState: false
        command: ["bluetoothctl", "power", targetState ? "on" : "off"]
        onRunningChanged: {
            if (!running) {
                btStatusProcess.running = true;
            }
        }
    }

    // Scan on/off
    Process {
        id: btScanProcess
        property bool targetState: false
        command: ["bluetoothctl", "scan", targetState ? "on" : "off"]
        onRunningChanged: {
            if (!running) {
                btStatusProcess.running = true;
                if (!targetState) {
                    btDevicesProcess.running = true;
                }
            }
        }
    }

    // Connect to device
    Process {
        id: btConnectProcess
        property string targetAddress: ""
        command: ["bluetoothctl", "connect", targetAddress]
        onRunningChanged: {
            if (!running) {
                btDevicesProcess.running = true;
            }
        }
    }

    // Disconnect from device
    Process {
        id: btDisconnectProcess
        property string targetAddress: ""
        command: ["bluetoothctl", "disconnect", targetAddress]
        onRunningChanged: {
            if (!running) {
                btDevicesProcess.running = true;
            }
        }
    }

    // Background refresh timer - updates device list every 10 seconds while visible
    Timer {
        interval: 10000
        running: bluetoothView.visible && bluetoothView.btPowered
        repeat: true
        onTriggered: btDevicesProcess.running = true
    }

    Column {
        id: bluetoothContent
        width: parent.width
        spacing: 8

        // Adapter controls
        Rectangle {
            width: parent.width
            height: 44
            radius: 6
            color: "#24283b"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                // Bluetooth icon
                Text {
                    text: "󰂯"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 18
                    color: bluetoothView.btPowered ? "#7aa2f7" : "#565f89"
                }

                // Status text
                Text {
                    text: bluetoothView.btPowered ? "Bluetooth On" : "Bluetooth Off"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    color: "#c0caf5"
                }

                Item { Layout.fillWidth: true }

                // Scan button
                Rectangle {
                    Layout.preferredWidth: scanText.implicitWidth + 16
                    Layout.preferredHeight: 28
                    radius: 4
                    color: scanMouse.containsMouse ? "#33467c" : "transparent"
                    border.color: bluetoothView.btScanning ? "#7aa2f7" : "#33467c"
                    border.width: 1
                    visible: bluetoothView.btPowered

                    Text {
                        id: scanText
                        anchors.centerIn: parent
                        text: bluetoothView.btScanning ? "󰍰 Scanning..." : "󰍉 Scan"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                        color: bluetoothView.btScanning ? "#7aa2f7" : "#c0caf5"
                    }

                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            btScanProcess.targetState = !bluetoothView.btScanning;
                            btScanProcess.running = true;
                        }
                    }
                }

                // Power toggle
                Rectangle {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 28
                    radius: 14
                    color: bluetoothView.btPowered ? "#7aa2f7" : "#33467c"

                    Rectangle {
                        width: 22
                        height: 22
                        radius: 11
                        color: "#c0caf5"
                        anchors.verticalCenter: parent.verticalCenter
                        x: bluetoothView.btPowered ? parent.width - width - 3 : 3

                        Behavior on x {
                            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            btPowerProcess.targetState = !bluetoothView.btPowered;
                            btPowerProcess.running = true;
                        }
                    }
                }
            }
        }

        // Devices list header
        Text {
            text: "Devices"
            font.family: "JetBrains Mono"
            font.pixelSize: 12
            font.bold: true
            color: "#565f89"
            visible: bluetoothView.btDevices.length > 0
        }

        // Device list
        ListView {
            id: bluetoothDeviceList
            width: parent.width
            height: Math.min(contentHeight, 280)
            clip: true
            spacing: 4
            visible: bluetoothView.btDevices.length > 0

            model: bluetoothView.btDevices

            delegate: Rectangle {
                required property var modelData
                required property int index

                width: bluetoothDeviceList.width
                height: 56
                radius: 6
                color: btDeviceMouse.containsMouse ? "#33467c" : "#24283b"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    // Device icon
                    Text {
                        text: {
                            var icon = modelData.icon || "";
                            if (icon.includes("phone")) return "󰏲";
                            if (icon.includes("audio") || icon.includes("headset") || icon.includes("headphone")) return "󰋋";
                            if (icon.includes("keyboard")) return "󰌌";
                            if (icon.includes("mouse")) return "󰍽";
                            if (icon.includes("computer")) return "󰍹";
                            return "󰂱";
                        }
                        font.family: "JetBrains Mono"
                        font.pixelSize: 20
                        color: modelData.connected ? "#7aa2f7" : "#565f89"
                    }

                    // Device info
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: modelData.name || modelData.address
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                            color: "#c0caf5"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: {
                                if (modelData.connected) return "Connected";
                                if (modelData.paired) return "Paired";
                                return "Available";
                            }
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                            color: modelData.connected ? "#7aa2f7" : "#565f89"
                            Layout.fillWidth: true
                        }
                    }

                    // Connect/Disconnect button
                    Rectangle {
                        Layout.preferredWidth: connectBtnText.implicitWidth + 16
                        Layout.preferredHeight: 28
                        radius: 4
                        color: connectBtnMouse.containsMouse ? (modelData.connected ? "#f7768e" : "#7aa2f7") : "transparent"
                        border.color: modelData.connected ? "#f7768e" : "#7aa2f7"
                        border.width: 1

                        Text {
                            id: connectBtnText
                            anchors.centerIn: parent
                            text: modelData.connected ? "Disconnect" : "Connect"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                            color: connectBtnMouse.containsMouse ? "#1a1b26" : (modelData.connected ? "#f7768e" : "#7aa2f7")
                        }

                        MouseArea {
                            id: connectBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.connected) {
                                    btDisconnectProcess.targetAddress = modelData.address;
                                    btDisconnectProcess.running = true;
                                } else {
                                    btConnectProcess.targetAddress = modelData.address;
                                    btConnectProcess.running = true;
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: btDeviceMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    z: -1
                }
            }

            ScrollBar.vertical: ScrollBar {
                active: true
                policy: ScrollBar.AsNeeded
            }
        }

        // Empty state
        Rectangle {
            width: parent.width
            height: 80
            radius: 6
            color: "#24283b"
            visible: bluetoothView.btDevices.length === 0 && bluetoothView.btPowered

            Column {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: bluetoothView.btScanning ? "Scanning for devices..." : "No devices found"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    color: "#565f89"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Click Scan to discover nearby devices"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    color: "#565f89"
                    visible: !bluetoothView.btScanning
                }
            }
        }

        // Adapter disabled state
        Rectangle {
            width: parent.width
            height: 60
            radius: 6
            color: "#24283b"
            visible: !bluetoothView.btPowered

            Text {
                anchors.centerIn: parent
                text: "Turn on Bluetooth to see devices"
                font.family: "JetBrains Mono"
                font.pixelSize: 14
                color: "#565f89"
            }
        }
    }
}
