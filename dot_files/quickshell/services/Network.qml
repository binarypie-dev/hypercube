pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Primary connection info (for status bar)
    property bool connected: false
    property string type: "none"  // wifi, ethernet, none
    property string name: ""
    property int strength: 0  // 0-100 for wifi
    property string ipAddress: ""
    property string device: ""

    // Hardware availability
    property bool wifiAvailable: false
    property bool ethernetAvailable: false
    property bool wifiEnabled: true

    // Wifi specific (for current connection)
    property string ssid: ""
    property string security: ""

    // List of all network interfaces
    property var interfaces: []

    // Available WiFi networks
    property var availableNetworks: []
    property bool scanning: false

    // Known/saved networks
    property var savedNetworks: []

    // VPN
    property bool vpnActive: false
    property string vpnName: ""

    // Parsing state
    property var pendingInterfaces: []
    property bool parsingInterfaces: false
    property var pendingNetworks: []
    property bool parsingNetworks: false
    property var pendingSaved: []
    property bool parsingSaved: false

    // Interface list script
    readonly property string interfaceListScript: `
        if command -v nmcli &>/dev/null; then
            # Check wifi radio state
            WIFI_STATE=$(nmcli radio wifi 2>/dev/null)
            if [ "$WIFI_STATE" = "enabled" ]; then
                echo "wifiEnabled=true"
            else
                echo "wifiEnabled=false"
            fi

            echo "INTERFACES_START"
            nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device 2>/dev/null | while IFS=: read -r dev type state conn; do
                # Skip loopback, bridge, tun, etc
                case "$type" in
                    ethernet|wifi)
                        # Get details for this device
                        IP=""
                        GW=""
                        MAC=""
                        SIGNAL=""
                        SECURITY=""
                        SSID=""

                        if [ "$state" = "connected" ]; then
                            IP=$(nmcli -t -f IP4.ADDRESS device show "$dev" 2>/dev/null | head -1 | cut -d: -f2 | cut -d/ -f1)
                            GW=$(nmcli -t -f IP4.GATEWAY device show "$dev" 2>/dev/null | head -1 | cut -d: -f2)
                        fi

                        MAC=$(nmcli -t -f GENERAL.HWADDR device show "$dev" 2>/dev/null | head -1 | cut -d: -f2-)

                        if [ "$type" = "wifi" ] && [ "$state" = "connected" ]; then
                            # Connection name is the SSID for wifi connections
                            SSID="$conn"
                            # Get signal and security by filtering wifi list to our specific SSID
                            WIFI_INFO=$(nmcli -t -f SIGNAL,SECURITY device wifi list ifname "$dev" ssid "$SSID" 2>/dev/null | head -1)
                            SIGNAL=$(echo "$WIFI_INFO" | cut -d: -f1)
                            SECURITY=$(echo "$WIFI_INFO" | cut -d: -f2-)
                        fi

                        echo "IFACE|$dev|$type|$state|$conn|$IP|$GW|$MAC|$SIGNAL|$SSID|$SECURITY"
                        ;;
                esac
            done
            echo "INTERFACES_END"

            # VPN check
            VPN=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep vpn | head -1)
            if [ -n "$VPN" ]; then
                echo "vpnActive=true"
                echo "vpnName=$(echo $VPN | cut -d: -f1)"
            else
                echo "vpnActive=false"
            fi
        fi
    `

    // WiFi scan script
    readonly property string wifiScanScript: `
        if command -v nmcli &>/dev/null; then
            echo "NETWORKS_START"
            nmcli -t -f SSID,SIGNAL,SECURITY,BSSID device wifi list --rescan yes 2>/dev/null | while IFS=: read -r ssid signal security bssid; do
                if [ -n "$ssid" ]; then
                    echo "NETWORK:$ssid:$signal:$security:$bssid"
                fi
            done
            echo "NETWORKS_END"
        fi
    `

    // Saved networks script
    readonly property string savedNetworksScript: `
        if command -v nmcli &>/dev/null; then
            echo "SAVED_START"
            nmcli -t -f NAME,TYPE connection show 2>/dev/null | grep "802-11-wireless" | while IFS=: read -r name type; do
                echo "SAVED:$name"
            done
            echo "SAVED_END"
        fi
    `

    Process {
        id: interfaceProcess
        command: ["sh", "-c", root.interfaceListScript]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.parseInterfaceLine(data)
        }

        onRunningChanged: {
            if (running) {
                root.pendingInterfaces = []
                root.parsingInterfaces = false
            }
        }

        onExited: root.finalizeInterfaces()
    }

    Process {
        id: wifiScanProcess
        command: ["sh", "-c", root.wifiScanScript]
        running: false

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.parseNetworkLine(data)
        }

        onRunningChanged: {
            if (running) {
                root.pendingNetworks = []
                root.parsingNetworks = false
            }
        }

        onExited: root.finalizeNetworks()
    }

    Process {
        id: savedNetworksProcess
        command: ["sh", "-c", root.savedNetworksScript]
        running: false

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.parseSavedLine(data)
        }

        onRunningChanged: {
            if (running) {
                root.pendingSaved = []
                root.parsingSaved = false
            }
        }

        onExited: root.finalizeSaved()
    }

    Process {
        id: wifiToggleProcess
        command: ["sh", "-c", ""]
        running: false
        onExited: root.refresh()
    }

    Process {
        id: connectProcess
        command: ["sh", "-c", ""]
        running: false
        onExited: root.refresh()
    }

    Process {
        id: disconnectProcess
        command: ["sh", "-c", ""]
        running: false
        onExited: root.refresh()
    }

    Process {
        id: forgetProcess
        command: ["sh", "-c", ""]
        running: false
        onExited: {
            root.loadSavedNetworks()
            root.refresh()
        }
    }

    function parseInterfaceLine(line) {
        if (!line || line.trim() === "") return

        if (line === "INTERFACES_START") {
            parsingInterfaces = true
            return
        }
        if (line === "INTERFACES_END") {
            parsingInterfaces = false
            return
        }

        if (parsingInterfaces && line.startsWith("IFACE|")) {
            const parts = line.substring(6).split("|")
            if (parts.length >= 4) {
                const iface = {
                    device: parts[0] || "",
                    type: parts[1] || "",
                    state: parts[2] || "",
                    connection: parts[3] || "",
                    ipAddress: parts[4] || "",
                    gateway: parts[5] || "",
                    macAddress: parts[6] || "",
                    strength: parseInt(parts[7]) || 0,
                    ssid: parts[8] || "",
                    security: parts[9] || ""
                }
                pendingInterfaces.push(iface)
            }
            return
        }

        // Parse other properties
        const idx = line.indexOf("=")
        if (idx !== -1) {
            const key = line.substring(0, idx).trim()
            const value = line.substring(idx + 1).trim()

            switch (key) {
                case "wifiEnabled":
                    wifiEnabled = value === "true"
                    break
                case "vpnActive":
                    vpnActive = value === "true"
                    break
                case "vpnName":
                    vpnName = value
                    break
            }
        }
    }

    function finalizeInterfaces() {
        let hasWifi = false
        let hasEthernet = false
        let primaryConnection = null

        for (const iface of pendingInterfaces) {
            if (iface.type === "wifi") hasWifi = true
            if (iface.type === "ethernet") hasEthernet = true

            // Track primary connection (first connected interface)
            if (iface.state === "connected" && !primaryConnection) {
                primaryConnection = iface
            }
        }

        interfaces = [...pendingInterfaces]
        wifiAvailable = hasWifi
        ethernetAvailable = hasEthernet

        // Update primary connection info for status bar
        if (primaryConnection) {
            connected = true
            type = primaryConnection.type
            name = primaryConnection.connection || primaryConnection.ssid || primaryConnection.device
            device = primaryConnection.device
            ipAddress = primaryConnection.ipAddress
            strength = primaryConnection.strength
            ssid = primaryConnection.ssid
            security = primaryConnection.security
        } else {
            connected = false
            type = "none"
            name = ""
            device = ""
            ipAddress = ""
            strength = 0
            ssid = ""
            security = ""
        }
    }

    function parseNetworkLine(line) {
        if (!line || line.trim() === "") return

        if (line === "NETWORKS_START") {
            parsingNetworks = true
            return
        }
        if (line === "NETWORKS_END") {
            parsingNetworks = false
            return
        }

        if (parsingNetworks && line.startsWith("NETWORK:")) {
            const parts = line.substring(8).split(":")
            if (parts.length >= 3) {
                pendingNetworks.push({
                    ssid: parts[0],
                    strength: parseInt(parts[1]) || 0,
                    security: parts[2] || "",
                    bssid: parts[3] || "",
                    saved: savedNetworks.includes(parts[0])
                })
            }
        }
    }

    function finalizeNetworks() {
        // Sort by signal strength
        pendingNetworks.sort((a, b) => b.strength - a.strength)

        // Remove duplicates (keep strongest signal)
        const seen = new Set()
        const filtered = pendingNetworks.filter(n => {
            if (seen.has(n.ssid)) return false
            seen.add(n.ssid)
            return true
        })

        availableNetworks = [...filtered]
        scanning = false
    }

    function parseSavedLine(line) {
        if (!line || line.trim() === "") return

        if (line === "SAVED_START") {
            parsingSaved = true
            return
        }
        if (line === "SAVED_END") {
            parsingSaved = false
            return
        }

        if (parsingSaved && line.startsWith("SAVED:")) {
            pendingSaved.push(line.substring(6))
        }
    }

    function finalizeSaved() {
        savedNetworks = [...pendingSaved]
    }

    // Update timer
    Timer {
        interval: 10000  // 10 seconds
        running: true
        repeat: true
        onTriggered: interfaceProcess.running = true
    }

    // Manually refresh
    function refresh() {
        interfaceProcess.running = true
    }

    // Start WiFi scan
    function startScan() {
        if (!wifiAvailable || !wifiEnabled) return
        scanning = true
        wifiScanProcess.running = true
    }

    // Load saved networks
    function loadSavedNetworks() {
        savedNetworksProcess.running = true
    }

    // Toggle WiFi on/off
    function setWifiEnabled(enabled) {
        wifiToggleProcess.command = ["sh", "-c", `nmcli radio wifi ${enabled ? "on" : "off"}`]
        wifiToggleProcess.running = true
    }

    // Connect to a network
    function connectToNetwork(ssid, password) {
        if (password) {
            connectProcess.command = ["sh", "-c", `nmcli device wifi connect "${ssid}" password "${password}"`]
        } else {
            connectProcess.command = ["sh", "-c", `nmcli connection up "${ssid}" 2>/dev/null || nmcli device wifi connect "${ssid}"`]
        }
        connectProcess.running = true
    }

    // Disconnect a specific device
    function disconnectDevice(deviceName) {
        disconnectProcess.command = ["sh", "-c", `nmcli device disconnect "${deviceName}"`]
        disconnectProcess.running = true
    }

    // Disconnect from current network (legacy)
    function disconnect() {
        if (device) {
            disconnectDevice(device)
        }
    }

    // Forget a saved network
    function forgetNetwork(ssid) {
        forgetProcess.command = ["sh", "-c", `nmcli connection delete "${ssid}"`]
        forgetProcess.running = true
    }

    Component.onCompleted: {
        loadSavedNetworks()
    }
}
