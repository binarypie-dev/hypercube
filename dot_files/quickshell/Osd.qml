import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Widgets

Scope {
    id: osdRoot

    property bool shouldShow: false
    property string osdType: "volume"  // "volume", "brightness", "mic"
    property real osdValue: 0
    property bool osdMuted: false
    property string osdIcon: ""
    property bool initialized: false

    // Delay initialization to ignore startup signals
    Timer {
        id: initTimer
        interval: 500
        running: true
        onTriggered: osdRoot.initialized = true
    }

    // Track Pipewire audio sink
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    // Track sink volume/mute changes
    property real sinkVolume: Pipewire.defaultAudioSink?.audio?.averageVolume ?? 0
    property bool sinkMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false

    onSinkVolumeChanged: {
        if (initialized)
            showOsd("volume", sinkVolume, sinkMuted);
    }
    onSinkMutedChanged: {
        if (initialized)
            showOsd("volume", sinkVolume, sinkMuted);
    }

    // Track source volume/mute changes
    property real sourceVolume: Pipewire.defaultAudioSource?.audio?.averageVolume ?? 0
    property bool sourceMuted: Pipewire.defaultAudioSource?.audio?.muted ?? false

    onSourceVolumeChanged: {
        if (initialized)
            showOsd("mic", sourceVolume, sourceMuted);
    }
    onSourceMutedChanged: {
        if (initialized)
            showOsd("mic", sourceVolume, sourceMuted);
    }

    // IPC handler for OSD commands
    IpcHandler {
        target: "osd"

        function volumeUp() {
            if (Pipewire.defaultAudioSink?.audio) {
                var newVol = Math.min(1.0, Pipewire.defaultAudioSink.audio.averageVolume + 0.05);
                Pipewire.defaultAudioSink.audio.averageVolume = newVol;
            }
        }

        function volumeDown() {
            if (Pipewire.defaultAudioSink?.audio) {
                var newVol = Math.max(0.0, Pipewire.defaultAudioSink.audio.averageVolume - 0.05);
                Pipewire.defaultAudioSink.audio.averageVolume = newVol;
            }
        }

        function volumeMute() {
            if (Pipewire.defaultAudioSink?.audio) {
                Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
            }
        }

        function micMute() {
            if (Pipewire.defaultAudioSource?.audio) {
                Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted;
            }
        }

        function brightnessUp() {
            brightnessProcess.command = ["brightnessctl", "set", "+5%"];
            brightnessProcess.running = true;
        }

        function brightnessDown() {
            brightnessProcess.command = ["brightnessctl", "set", "5%-"];
            brightnessProcess.running = true;
        }
    }

    // Brightness control process
    Process {
        id: brightnessProcess
        onExited: {
            // Read current brightness after change
            getBrightnessProcess.running = true;
        }
    }

    Process {
        id: getBrightnessProcess
        command: ["brightnessctl", "-m"]
        stdout: SplitParser {
            onRead: (line) => {
                // Format: device,class,current,max,percentage%
                var parts = line.split(",");
                if (parts.length >= 5) {
                    var percent = parseInt(parts[4].replace("%", "")) / 100;
                    osdRoot.showOsd("brightness", percent, false);
                }
            }
        }
    }

    function showOsd(type, value, muted) {
        osdType = type;
        osdValue = value;
        osdMuted = muted;

        // Set icon based on type and state
        if (type === "volume") {
            if (muted) {
                osdIcon = "󰝟";
            } else if (value > 0.66) {
                osdIcon = "󰕾";
            } else if (value > 0.33) {
                osdIcon = "󰖀";
            } else if (value > 0) {
                osdIcon = "󰕿";
            } else {
                osdIcon = "󰝟";
            }
        } else if (type === "brightness") {
            if (value > 0.66) {
                osdIcon = "󰃠";
            } else if (value > 0.33) {
                osdIcon = "󰃟";
            } else {
                osdIcon = "󰃞";
            }
        } else if (type === "mic") {
            osdIcon = muted ? "󰍭" : "󰍬";
        }

        shouldShow = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: osdRoot.shouldShow = false
    }

    // OSD Window
    LazyLoader {
        active: osdRoot.shouldShow

        PanelWindow {
            anchors.bottom: true
            margins.bottom: screen.height / 6

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay

            implicitWidth: 300
            implicitHeight: 60
            color: "transparent"

            // Don't block input
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: "#e01a1b26"
                border.color: "#33467c"
                border.width: 1

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 16
                        rightMargin: 16
                    }
                    spacing: 16

                    // Icon
                    Text {
                        text: osdRoot.osdIcon
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 28
                        color: osdRoot.osdMuted ? "#f7768e" : "#7aa2f7"
                    }

                    // Progress bar
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        radius: 4
                        color: "#33467c"

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: parent.width * osdRoot.osdValue
                            radius: parent.radius
                            color: osdRoot.osdMuted ? "#f7768e" : "#7aa2f7"

                            Behavior on width {
                                NumberAnimation { duration: 100 }
                            }
                        }
                    }

                    // Percentage
                    Text {
                        text: Math.round(osdRoot.osdValue * 100) + "%"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: "#c0caf5"
                        Layout.preferredWidth: 45
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }
}
