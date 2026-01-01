pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Audio control via PipeWire/PulseAudio
Singleton {
    id: root

    // Sink (output) properties
    property real volume: 0.75
    property bool muted: false
    property string sinkName: ""
    property string sinkDescription: ""
    property int defaultSinkId: -1

    // Source (input) properties
    property real micVolume: 1.0
    property bool micMuted: false
    property string sourceName: ""
    property string sourceDescription: ""
    property int defaultSourceId: -1

    // Available devices
    property var sinks: []      // [{id, name, description, isDefault}]
    property var sources: []    // [{id, name, description, isDefault}]

    // Active streams
    property int activeStreams: 0

    // Pending device lists during parsing
    property var pendingSinks: []
    property var pendingSources: []
    property bool parsingSinks: false
    property bool parsingSources: false

    // Device list query script (using pactl for reliable parsing)
    readonly property string deviceListScript: "
        if command -v pactl &>/dev/null; then
            # Get default sink and source names
            DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null)
            DEFAULT_SOURCE=$(pactl get-default-source 2>/dev/null)

            # List sinks
            echo \"sinks_start\"
            pactl list sinks 2>/dev/null | awk '
                /^Sink #/ { id = substr($2, 2) }
                /^\\tName:/ { name = $2 }
                /^\\tDescription:/ {
                    desc = substr($0, index($0, \":\")+2)
                    print \"sink|\" id \"|\" name \"|\" desc
                }
            ' | while IFS='|' read -r type id name desc; do
                IS_DEFAULT=\"false\"
                if [ \"$name\" = \"$DEFAULT_SINK\" ]; then
                    IS_DEFAULT=\"true\"
                fi
                echo \"sink|$id|$name|$desc|$IS_DEFAULT\"
            done
            echo \"sinks_end\"

            # List sources (exclude monitors)
            echo \"sources_start\"
            pactl list sources 2>/dev/null | awk '
                /^Source #/ { id = substr($2, 2) }
                /^\\tName:/ { name = $2 }
                /^\\tDescription:/ {
                    desc = substr($0, index($0, \":\")+2)
                    print \"source|\" id \"|\" name \"|\" desc
                }
            ' | grep -v \"Monitor of\" | while IFS='|' read -r type id name desc; do
                IS_DEFAULT=\"false\"
                if [ \"$name\" = \"$DEFAULT_SOURCE\" ]; then
                    IS_DEFAULT=\"true\"
                fi
                echo \"source|$id|$name|$desc|$IS_DEFAULT\"
            done
            echo \"sources_end\"
        fi
    "

    // Audio query script
    readonly property string audioQueryScript: "
        if command -v wpctl &>/dev/null; then
            SINK_VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
            if [ -n \"$SINK_VOL\" ]; then
                VOL=$(echo \"$SINK_VOL\" | awk '{print $2}')
                echo \"volume=$VOL\"
                if echo \"$SINK_VOL\" | grep -q \"MUTED\"; then
                    echo \"muted=true\"
                else
                    echo \"muted=false\"
                fi
            fi

            SOURCE_VOL=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)
            if [ -n \"$SOURCE_VOL\" ]; then
                VOL=$(echo \"$SOURCE_VOL\" | awk '{print $2}')
                echo \"micVolume=$VOL\"
                if echo \"$SOURCE_VOL\" | grep -q \"MUTED\"; then
                    echo \"micMuted=true\"
                else
                    echo \"micMuted=false\"
                fi
            fi

            SINK_INFO=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep \"node.description\" | head -1 | cut -d'\"' -f2)
            echo \"sinkDescription=$SINK_INFO\"

        elif command -v pactl &>/dev/null; then
            SINK=$(pactl get-default-sink 2>/dev/null)
            if [ -n \"$SINK\" ]; then
                VOL=$(pactl get-sink-volume \"$SINK\" 2>/dev/null | head -1 | sed 's/.*\\/ *\\([0-9]*\\)%.*/\\1/')
                echo \"volume=$(echo \"scale=2; $VOL/100\" | bc)\"

                MUTE=$(pactl get-sink-mute \"$SINK\" 2>/dev/null | grep -c \"yes\")
                if [ \"$MUTE\" = \"1\" ]; then
                    echo \"muted=true\"
                else
                    echo \"muted=false\"
                fi
            fi

            SOURCE=$(pactl get-default-source 2>/dev/null)
            if [ -n \"$SOURCE\" ]; then
                VOL=$(pactl get-source-volume \"$SOURCE\" 2>/dev/null | head -1 | sed 's/.*\\/ *\\([0-9]*\\)%.*/\\1/')
                echo \"micVolume=$(echo \"scale=2; $VOL/100\" | bc)\"

                MUTE=$(pactl get-source-mute \"$SOURCE\" 2>/dev/null | grep -c \"yes\")
                if [ \"$MUTE\" = \"1\" ]; then
                    echo \"micMuted=true\"
                else
                    echo \"micMuted=false\"
                fi
            fi
        fi
    "

    // Run initial device query on startup
    Component.onCompleted: {
        deviceListProcess.running = true
    }

    Process {
        id: audioProcess
        command: ["sh", "-c", root.audioQueryScript]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.parseVolumeLine(data)
        }
    }

    Process {
        id: deviceListProcess
        command: ["sh", "-c", root.deviceListScript]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.parseDeviceLine(data)
        }

        onRunningChanged: {
            if (running) {
                root.pendingSinks = []
                root.pendingSources = []
                root.parsingSinks = false
                root.parsingSources = false
            }
        }

        onExited: {
            root.sinks = root.pendingSinks
            root.sources = root.pendingSources
        }
    }

    function parseVolumeLine(line) {
        if (!line || line.trim() === "") return

        const idx = line.indexOf("=")
        if (idx === -1) return

        const key = line.substring(0, idx).trim()
        const value = line.substring(idx + 1).trim()

        switch (key) {
            case "volume":
                // Cap at 1.0 (100%) - don't allow over-amplification display
                volume = Math.min(1.0, parseFloat(value) || 0.75)
                break
            case "muted":
                muted = value === "true"
                break
            case "micVolume":
                // Cap at 1.0 (100%) - don't allow over-amplification display
                micVolume = Math.min(1.0, parseFloat(value) || 1.0)
                break
            case "micMuted":
                micMuted = value === "true"
                break
            case "sinkName":
                sinkName = value
                break
            case "sinkDescription":
                sinkDescription = value
                break
            case "sourceName":
                sourceName = value
                break
            case "sourceDescription":
                sourceDescription = value
                break
        }
    }

    function parseDeviceLine(line) {
        if (!line || line.trim() === "") return

        // Parse device list markers
        if (line === "sinks_start") {
            parsingSinks = true
            parsingSources = false
            return
        }
        if (line === "sinks_end") {
            parsingSinks = false
            return
        }
        if (line === "sources_start") {
            parsingSources = true
            parsingSinks = false
            return
        }
        if (line === "sources_end") {
            parsingSources = false
            return
        }

        // Parse sink entries: sink|id|name|description|isDefault
        if (parsingSinks && line.startsWith("sink|")) {
            const parts = line.split("|")
            if (parts.length >= 5) {
                pendingSinks.push({
                    id: parseInt(parts[1]),
                    name: parts[2],
                    description: parts[3],
                    isDefault: parts[4] === "true"
                })
            }
            return
        }

        // Parse source entries: source|id|name|description|isDefault
        if (parsingSources && line.startsWith("source|")) {
            const parts = line.split("|")
            if (parts.length >= 5) {
                pendingSources.push({
                    id: parseInt(parts[1]),
                    name: parts[2],
                    description: parts[3],
                    isDefault: parts[4] === "true"
                })
            }
            return
        }

        // Parse default IDs
        const idx = line.indexOf("=")
        if (idx === -1) return

        const key = line.substring(0, idx).trim()
        const value = line.substring(idx + 1).trim()

        switch (key) {
            case "defaultSinkId":
                defaultSinkId = parseInt(value) || -1
                break
            case "defaultSourceId":
                defaultSourceId = parseInt(value) || -1
                break
        }
    }

    // Update timer for volume (fast)
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: audioProcess.running = true
    }

    // Update timer for device list (slower)
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: deviceListProcess.running = true
    }

    // Control functions
    function setVolume(value) {
        // Cap at 100% - no over-amplification
        const clampedValue = Math.min(1.0, Math.max(0, value))
        const percent = Math.round(clampedValue * 100)
        volumeProcess.command = ["sh", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + percent + "% || pactl set-sink-volume @DEFAULT_SINK@ " + percent + "%"]
        volumeProcess.running = true
        volume = clampedValue
    }

    Process {
        id: volumeProcess
        command: ["true"]
    }

    function setMuted(mute) {
        const state = mute ? "1" : "0"
        muteProcess.command = ["sh", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ " + state + " || pactl set-sink-mute @DEFAULT_SINK@ " + (mute ? "yes" : "no")]
        muteProcess.running = true
        muted = mute
    }

    Process {
        id: muteProcess
        command: ["true"]
    }

    function toggleMute() {
        setMuted(!muted)
    }

    function setMicVolume(value) {
        // Cap at 100% - no over-amplification
        const clampedValue = Math.min(1.0, Math.max(0, value))
        const percent = Math.round(clampedValue * 100)
        micVolumeProcess.command = ["sh", "-c", "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + percent + "% || pactl set-source-volume @DEFAULT_SOURCE@ " + percent + "%"]
        micVolumeProcess.running = true
        micVolume = clampedValue
    }

    Process {
        id: micVolumeProcess
        command: ["true"]
    }

    function setMicMuted(mute) {
        const state = mute ? "1" : "0"
        micMuteProcess.command = ["sh", "-c", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ " + state + " || pactl set-source-mute @DEFAULT_SOURCE@ " + (mute ? "yes" : "no")]
        micMuteProcess.running = true
        micMuted = mute
    }

    Process {
        id: micMuteProcess
        command: ["true"]
    }

    function toggleMicMute() {
        setMicMuted(!micMuted)
    }

    function setDefaultSink(name) {
        setSinkProcess.command = ["pactl", "set-default-sink", name]
        setSinkProcess.running = true
    }

    Process {
        id: setSinkProcess
        command: ["true"]
        onExited: deviceListProcess.running = true
    }

    function setDefaultSource(name) {
        setSourceProcess.command = ["pactl", "set-default-source", name]
        setSourceProcess.running = true
    }

    Process {
        id: setSourceProcess
        command: ["true"]
        onExited: deviceListProcess.running = true
    }

    function refreshDevices() {
        deviceListProcess.running = true
    }

    // Volume as percentage
    function volumePercent() {
        return Math.round(volume * 100)
    }

    function micVolumePercent() {
        return Math.round(micVolume * 100)
    }
}
