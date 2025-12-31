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
                            WIFI_INFO=$(nmcli -t -f SIGNAL,SSID,SECURITY device wifi list ifname "$dev" 2>/dev/null | head -1)
                            SIGNAL=$(echo "$WIFI_INFO" | cut -d: -f1)
                            SSID=$(echo "$WIFI_INFO" | cut -d: -f2)
                            SECURITY=$(echo "$WIFI_INFO" | cut -d: -f3)
                        fi

                        echo "IFACE:$dev:$type:$state:$conn:$IP:$GW:$MAC:$SIGNAL:$SSID:$SECURITY"
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
        onExited: root.parseInterfaces()
    }

    Process {
        id: wifiScanProcess
        command: ["sh", "-c", root.wifiScanScript]
        running: false
        onExited: root.parseWifiScan()
    }

    Process {
        id: savedNetworksProcess
        command: ["sh", "-c", root.savedNetworksScript]
        running: false
        onExited: root.parseSavedNetworks()
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

    function parseInterfaces() {
        const output = interfaceProcess.stdout
        if (!output) return

        const lines = output.split("\n")
        let ifaces = []
        let inInterfaces = false
        let hasWifi = false
        let hasEthernet = false
        let primaryConnection = null

        for (const line of lines) {
            if (line === "INTERFACES_START") {
                inInterfaces = true
                continue
            }
            if (line === "INTERFACES_END") {
                inInterfaces = false
                continue
            }

            if (inInterfaces && line.startsWith("IFACE:")) {
                const parts = line.substring(6).split(":")
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

                    if (iface.type === "wifi") hasWifi = true
                    if (iface.type === "ethernet") hasEthernet = true

                    // Track primary connection (first connected interface)
                    if (iface.state === "connected" && !primaryConnection) {
                        primaryConnection = iface
                    }

                    ifaces.push(iface)
                }
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

        interfaces = [...ifaces]
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

    function parseWifiScan() {
        const output = wifiScanProcess.stdout
        if (!output) {
            scanning = false
            return
        }

        const lines = output.split("\n")
        let networks = []
        let inNetworks = false

        for (const line of lines) {
            if (line === "NETWORKS_START") {
                inNetworks = true
                continue
            }
            if (line === "NETWORKS_END") {
                inNetworks = false
                continue
            }
            if (inNetworks && line.startsWith("NETWORK:")) {
                const parts = line.substring(8).split(":")
                if (parts.length >= 3) {
                    networks.push({
                        ssid: parts[0],
                        strength: parseInt(parts[1]) || 0,
                        security: parts[2] || "",
                        bssid: parts[3] || "",
                        saved: savedNetworks.includes(parts[0])
                    })
                }
            }
        }

        // Sort by signal strength
        networks.sort((a, b) => b.strength - a.strength)

        // Remove duplicates (keep strongest signal)
        const seen = new Set()
        const filtered = networks.filter(n => {
            if (seen.has(n.ssid)) return false
            seen.add(n.ssid)
            return true
        })
        availableNetworks = [...filtered]

        scanning = false
    }

    function parseSavedNetworks() {
        const output = savedNetworksProcess.stdout
        if (!output) return

        const lines = output.split("\n")
        let saved = []
        let inSaved = false

        for (const line of lines) {
            if (line === "SAVED_START") {
                inSaved = true
                continue
            }
            if (line === "SAVED_END") {
                inSaved = false
                continue
            }
            if (inSaved && line.startsWith("SAVED:")) {
                saved.push(line.substring(6))
            }
        }

        savedNetworks = [...saved]
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
