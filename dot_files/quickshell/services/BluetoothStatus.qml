pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool powered: false
    property bool discovering: false
    property bool connected: false
    property string connectedDeviceName: ""

    property var devices: []  // List of paired devices
    property var availableDevices: []  // List of discovered (not paired) devices

    // Bluetooth query script
    readonly property string btQueryScript: "
        if ! command -v bluetoothctl &>/dev/null; then
            echo \"available=false\"
            exit 0
        fi

        echo \"available=true\"

        CTRL=$(bluetoothctl show 2>/dev/null)
        if [ -z \"$CTRL\" ]; then
            echo \"powered=false\"
            exit 0
        fi

        if echo \"$CTRL\" | grep -q \"Powered: yes\"; then
            echo \"powered=true\"
        else
            echo \"powered=false\"
        fi

        if echo \"$CTRL\" | grep -q \"Discovering: yes\"; then
            echo \"discovering=true\"
        else
            echo \"discovering=false\"
        fi

        CONNECTED=$(bluetoothctl devices Connected 2>/dev/null)
        if [ -n \"$CONNECTED\" ]; then
            echo \"connected=true\"
            FIRST_DEV=$(echo \"$CONNECTED\" | head -1 | sed 's/Device [^ ]* //')
            echo \"connectedDeviceName=$FIRST_DEV\"
        else
            echo \"connected=false\"
            echo \"connectedDeviceName=\"
        fi

        # Get paired devices
        echo \"devices_start\"
        bluetoothctl devices Paired 2>/dev/null | while read -r line; do
            MAC=$(echo \"$line\" | awk '{print $2}')
            NAME=$(echo \"$line\" | sed 's/Device [^ ]* //')
            if bluetoothctl info \"$MAC\" 2>/dev/null | grep -q \"Connected: yes\"; then
                echo \"device|$MAC|$NAME|connected\"
            else
                echo \"device|$MAC|$NAME|paired\"
            fi
        done
        echo \"devices_end\"

        # Get discovered but not paired devices
        echo \"available_start\"
        PAIRED=$(bluetoothctl devices Paired 2>/dev/null | awk '{print $2}')
        bluetoothctl devices 2>/dev/null | while read -r line; do
            MAC=$(echo \"$line\" | awk '{print $2}')
            NAME=$(echo \"$line\" | sed 's/Device [^ ]* //')
            # Skip if already paired
            if ! echo \"$PAIRED\" | grep -q \"$MAC\"; then
                echo \"available|$MAC|$NAME\"
            fi
        done
        echo \"available_end\"
    "

    // Accumulated output from the process
    property string btOutput: ""
    property var pendingDevices: []
    property var pendingAvailable: []
    property bool parsingDevices: false
    property bool parsingAvailableDevices: false

    // Run initial query on startup
    Component.onCompleted: {
        btProcess.running = true
    }

    Process {
        id: btProcess
        command: ["sh", "-c", root.btQueryScript]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.parseLine(data)
        }

        onRunningChanged: {
            if (running) {
                // Reset state when process starts
                root.pendingDevices = []
                root.pendingAvailable = []
                root.parsingDevices = false
                root.parsingAvailableDevices = false
            }
        }

        onExited: {
            // Finalize device lists
            root.devices = root.pendingDevices
            root.availableDevices = root.pendingAvailable
        }
    }

    function parseLine(line) {
        if (!line || line.trim() === "") return

        if (line === "devices_start") {
            parsingDevices = true
            parsingAvailableDevices = false
            return
        }
        if (line === "devices_end") {
            parsingDevices = false
            return
        }
        if (line === "available_start") {
            parsingAvailableDevices = true
            parsingDevices = false
            return
        }
        if (line === "available_end") {
            parsingAvailableDevices = false
            return
        }

        if (parsingDevices && line.startsWith("device|")) {
            const parts = line.split("|")
            if (parts.length >= 4) {
                pendingDevices.push({
                    mac: parts[1],
                    name: parts[2],
                    status: parts[3]
                })
            }
            return
        }

        if (parsingAvailableDevices && line.startsWith("available|")) {
            const parts = line.split("|")
            if (parts.length >= 3) {
                pendingAvailable.push({
                    mac: parts[1],
                    name: parts[2]
                })
            }
            return
        }

        const idx = line.indexOf("=")
        if (idx === -1) return

        const key = line.substring(0, idx).trim()
        const value = line.substring(idx + 1).trim()

        switch (key) {
            case "available":
                available = value === "true"
                break
            case "powered":
                powered = value === "true"
                break
            case "discovering":
                discovering = value === "true"
                break
            case "connected":
                connected = value === "true"
                break
            case "connectedDeviceName":
                connectedDeviceName = value
                break
        }
    }

    // Update timer - faster when discovering
    Timer {
        interval: root.discovering ? 2000 : 10000
        running: true
        repeat: true
        onTriggered: btProcess.running = true
    }

    // Control processes
    Process {
        id: powerProcess
        command: ["bluetoothctl", "power", "on"]
        onExited: btProcess.running = true
    }

    // Scan process - runs continuously while discovering
    Process {
        id: scanProcess
        command: ["bluetoothctl", "--timeout", "30", "scan", "on"]

        onExited: {
            // Scan finished (timeout or stopped)
            if (root.discovering) {
                root.discovering = false
                btProcess.running = true
            }
        }
    }

    Process {
        id: connectProcess
        command: ["bluetoothctl", "connect", ""]
        onExited: btProcess.running = true
    }

    Process {
        id: disconnectProcess
        command: ["bluetoothctl", "disconnect", ""]
        onExited: btProcess.running = true
    }

    Process {
        id: forgetProcess
        command: ["bluetoothctl", "remove", ""]
        onExited: btProcess.running = true
    }

    Process {
        id: pairProcess
        command: ["bluetoothctl", "pair", ""]
        onExited: btProcess.running = true
    }

    // Control functions
    function setPower(on) {
        powerProcess.command = ["bluetoothctl", "power", on ? "on" : "off"]
        powerProcess.running = true
        powered = on  // Optimistic update
    }

    function startDiscovery() {
        if (scanProcess.running) return  // Already scanning
        scanProcess.command = ["bluetoothctl", "--timeout", "30", "scan", "on"]
        scanProcess.running = true
        discovering = true  // Optimistic update
    }

    function stopDiscovery() {
        if (scanProcess.running) {
            scanProcess.running = false  // Kill the scan process
        }
        discovering = false
        btProcess.running = true  // Refresh state
    }

    function connectDevice(mac) {
        connectProcess.command = ["bluetoothctl", "connect", mac]
        connectProcess.running = true
    }

    function disconnectDevice(mac) {
        disconnectProcess.command = ["bluetoothctl", "disconnect", mac]
        disconnectProcess.running = true
    }

    function forgetDevice(mac) {
        forgetProcess.command = ["bluetoothctl", "remove", mac]
        forgetProcess.running = true
    }

    function pairDevice(mac) {
        // Enable pairable mode, then pair, then connect
        pairProcess.command = ["sh", "-c", "bluetoothctl pairable on && bluetoothctl pair " + mac + " && bluetoothctl trust " + mac + " && bluetoothctl connect " + mac]
        pairProcess.running = true
    }

    function clearAvailableDevices() {
        availableDevices = []
    }

    function refresh() {
        btProcess.running = true
    }
}
