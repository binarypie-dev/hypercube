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

    // Track Pipewire audio sink
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    // Watch for volume changes
    Connections {
        target: Pipewire.defaultAudioSink?.audio

        function onVolumeChanged() {
            osdRoot.showOsd("volume", Pipewire.defaultAudioSink.audio.volume, Pipewire.defaultAudioSink.audio.muted);
        }

        function onMutedChanged() {
            osdRoot.showOsd("volume", Pipewire.defaultAudioSink.audio.volume, Pipewire.defaultAudioSink.audio.muted);
        }
    }

    // Watch for mic changes
    Connections {
        target: Pipewire.defaultAudioSource?.audio

        function onVolumeChanged() {
            osdRoot.showOsd("mic", Pipewire.defaultAudioSource.audio.volume, Pipewire.defaultAudioSource.audio.muted);
        }

        function onMutedChanged() {
            osdRoot.showOsd("mic", Pipewire.defaultAudioSource.audio.volume, Pipewire.defaultAudioSource.audio.muted);
        }
    }

    // IPC handler for OSD commands
    IpcHandler {
        target: "osd"

        function volumeUp() {
            if (Pipewire.defaultAudioSink) {
                var newVol = Math.min(1.0, Pipewire.defaultAudioSink.audio.volume + 0.05);
                Pipewire.defaultAudioSink.audio.volume = newVol;
            }
        }

        function volumeDown() {
            if (Pipewire.defaultAudioSink) {
                var newVol = Math.max(0.0, Pipewire.defaultAudioSink.audio.volume - 0.05);
                Pipewire.defaultAudioSink.audio.volume = newVol;
            }
        }

        function volumeMute() {
            if (Pipewire.defaultAudioSink) {
                Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
            }
        }

        function micMute() {
            if (Pipewire.defaultAudioSource) {
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
