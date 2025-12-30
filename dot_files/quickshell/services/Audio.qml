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

    // Source (input) properties
    property real micVolume: 1.0
    property bool micMuted: false
    property string sourceName: ""
    property string sourceDescription: ""

    // Active streams
    property int activeStreams: 0

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

    Process {
        id: audioProcess
        command: ["sh", "-c", root.audioQueryScript]
        running: true

        onExited: root.parseOutput(this.stdout)
    }

    function parseOutput(output) {
        if (!output) return
        const lines = output.split("\n")

        for (const line of lines) {
            const idx = line.indexOf("=")
            if (idx === -1) continue

            const key = line.substring(0, idx).trim()
            const value = line.substring(idx + 1).trim()

            switch (key) {
                case "volume":
                    volume = parseFloat(value) || 0.75
                    break
                case "muted":
                    muted = value === "true"
                    break
                case "micVolume":
                    micVolume = parseFloat(value) || 1.0
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
    }

    // Update timer
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: audioProcess.running = true
    }

    // Control functions
    function setVolume(value) {
        const percent = Math.round(value * 100)
        volumeProcess.command = ["sh", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + percent + "% || pactl set-sink-volume @DEFAULT_SINK@ " + percent + "%"]
        volumeProcess.running = true
        volume = value
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
        const percent = Math.round(value * 100)
        micVolumeProcess.command = ["sh", "-c", "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + percent + "% || pactl set-source-volume @DEFAULT_SOURCE@ " + percent + "%"]
        micVolumeProcess.running = true
        micVolume = value
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

    // Volume as percentage
    function volumePercent() {
        return Math.round(volume * 100)
    }

    function micVolumePercent() {
        return Math.round(micVolume * 100)
    }
}
