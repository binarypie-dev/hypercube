pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool connected: false
    property string type: "none"  // wifi, ethernet, none
    property string name: ""
    property int strength: 0  // 0-100 for wifi
    property string ipAddress: ""

    // Hardware availability
    property bool wifiAvailable: false
    property bool ethernetAvailable: false

    // Wifi specific
    property string ssid: ""
    property string bssid: ""
    property int frequency: 0
    property string security: ""

    // VPN
    property bool vpnActive: false
    property string vpnName: ""

    // Network query script
    readonly property string networkQueryScript: "
        if command -v nmcli &>/dev/null; then
            # Check hardware availability
            if nmcli device 2>/dev/null | grep -q wifi; then
                echo \"wifiAvailable=true\"
            else
                echo \"wifiAvailable=false\"
            fi
            if nmcli device 2>/dev/null | grep -q ethernet; then
                echo \"ethernetAvailable=true\"
            else
                echo \"ethernetAvailable=false\"
            fi

            CONN=$(nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null | head -1)
            if [ -n \"$CONN\" ]; then
                NAME=$(echo \"$CONN\" | cut -d: -f1)
                TYPE=$(echo \"$CONN\" | cut -d: -f2)
                DEVICE=$(echo \"$CONN\" | cut -d: -f3)

                echo \"connected=true\"
                echo \"name=$NAME\"

                case \"$TYPE\" in
                    *wireless*|*wifi*)
                        echo \"type=wifi\"
                        WIFI_INFO=$(nmcli -t -f SIGNAL,SSID,BSSID,FREQ,SECURITY device wifi list ifname \"$DEVICE\" 2>/dev/null | grep \"^\" | head -1)
                        if [ -n \"$WIFI_INFO\" ]; then
                            echo \"strength=$(echo $WIFI_INFO | cut -d: -f1)\"
                            echo \"ssid=$(echo $WIFI_INFO | cut -d: -f2)\"
                            echo \"frequency=$(echo $WIFI_INFO | cut -d: -f4 | tr -d ' MHz')\"
                            echo \"security=$(echo $WIFI_INFO | cut -d: -f5)\"
                        fi
                        ;;
                    *ethernet*)
                        echo \"type=ethernet\"
                        echo \"strength=100\"
                        ;;
                    *)
                        echo \"type=other\"
                        ;;
                esac

                IP=$(nmcli -t -f IP4.ADDRESS device show \"$DEVICE\" 2>/dev/null | head -1 | cut -d: -f2 | cut -d/ -f1)
                if [ -n \"$IP\" ]; then
                    echo \"ipAddress=$IP\"
                fi
            else
                echo \"connected=false\"
                echo \"type=none\"
            fi

            VPN=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep vpn | head -1)
            if [ -n \"$VPN\" ]; then
                echo \"vpnActive=true\"
                echo \"vpnName=$(echo $VPN | cut -d: -f1)\"
            else
                echo \"vpnActive=false\"
            fi
        else
            # Check for wifi interfaces
            if ls /sys/class/net/wl* 2>/dev/null | grep -q .; then
                echo \"wifiAvailable=true\"
            else
                echo \"wifiAvailable=false\"
            fi
            # Check for ethernet interfaces
            if ls /sys/class/net/e* 2>/dev/null | grep -q .; then
                echo \"ethernetAvailable=true\"
            else
                echo \"ethernetAvailable=false\"
            fi

            if ip route get 1.1.1.1 &>/dev/null; then
                echo \"connected=true\"
                IFACE=$(ip route get 1.1.1.1 | head -1 | awk '{print $5}')
                echo \"name=$IFACE\"
                if [[ \"$IFACE\" == wl* ]]; then
                    echo \"type=wifi\"
                else
                    echo \"type=ethernet\"
                fi
            else
                echo \"connected=false\"
                echo \"type=none\"
            fi
        fi
    "

    Process {
        id: networkProcess
        command: ["sh", "-c", root.networkQueryScript]
        running: true
        onExited: root.parseOutput()
    }

    function parseOutput() {
        const output = networkProcess.stdout
        if (!output) return
        const lines = output.split("\n")

        for (const line of lines) {
            const idx = line.indexOf("=")
            if (idx === -1) continue

            const key = line.substring(0, idx).trim()
            const value = line.substring(idx + 1).trim()

            switch (key) {
                case "connected":
                    connected = value === "true"
                    break
                case "type":
                    type = value
                    break
                case "name":
                    name = value
                    break
                case "strength":
                    strength = parseInt(value) || 0
                    break
                case "ssid":
                    ssid = value
                    break
                case "bssid":
                    bssid = value
                    break
                case "frequency":
                    frequency = parseInt(value) || 0
                    break
                case "security":
                    security = value
                    break
                case "ipAddress":
                    ipAddress = value
                    break
                case "vpnActive":
                    vpnActive = value === "true"
                    break
                case "vpnName":
                    vpnName = value
                    break
                case "wifiAvailable":
                    wifiAvailable = value === "true"
                    break
                case "ethernetAvailable":
                    ethernetAvailable = value === "true"
                    break
            }
        }
    }

    // Update timer
    Timer {
        interval: 10000  // 10 seconds
        running: true
        repeat: true
        onTriggered: networkProcess.running = true
    }

    // Manually refresh
    function refresh() {
        networkProcess.running = true
    }
}
