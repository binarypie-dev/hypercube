/* Hypercube Calamares Slideshow */

import QtQuick 2.15
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1b26"

            Column {
                anchors.centerIn: parent
                spacing: 30

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Welcome to Hypercube"
                    font.pixelSize: 32
                    font.bold: true
                    color: "#c0caf5"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "A developer-focused workstation with Hyprland"
                    font.pixelSize: 18
                    color: "#a9b1d6"
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1b26"

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Hyprland Desktop"
                    font.pixelSize: 28
                    font.bold: true
                    color: "#7aa2f7"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Modern, tiling Wayland compositor"
                    font.pixelSize: 16
                    color: "#a9b1d6"
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Text { text: "• Smooth animations and effects"; color: "#c0caf5"; font.pixelSize: 14 }
                    Text { text: "• Dynamic tiling and workspaces"; color: "#c0caf5"; font.pixelSize: 14 }
                    Text { text: "• Waybar status bar"; color: "#c0caf5"; font.pixelSize: 14 }
                    Text { text: "• Quickshell launcher"; color: "#c0caf5"; font.pixelSize: 14 }
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1b26"

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Developer Experience"
                    font.pixelSize: 28
                    font.bold: true
                    color: "#bb9af7"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Everything you need to be productive"
                    font.pixelSize: 16
                    color: "#a9b1d6"
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Text { text: "• Distrobox for isolated dev environments"; color: "#c0caf5"; font.pixelSize: 14 }
                    Text { text: "• Homebrew via bluefin-cli container"; color: "#c0caf5"; font.pixelSize: 14 }
                    Text { text: "• Docker & Podman container runtimes"; color: "#c0caf5"; font.pixelSize: 14 }
                    Text { text: "• kubectl, kind, helm for Kubernetes"; color: "#c0caf5"; font.pixelSize: 14 }
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1b26"

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Modern Tooling"
                    font.pixelSize: 28
                    font.bold: true
                    color: "#9ece6a"
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Text { text: "• Ghostty & WezTerm terminals"; color: "#c0caf5"; font.pixelSize: 14 }
                    Text { text: "• Neovim with nightly builds"; color: "#c0caf5"; font.pixelSize: 14 }
                    Text { text: "• Fish shell with Starship prompt"; color: "#c0caf5"; font.pixelSize: 14 }
                    Text { text: "• Lazygit for git workflows"; color: "#c0caf5"; font.pixelSize: 14 }
                    Text { text: "• ripgrep, fd, eza, bat, zoxide"; color: "#c0caf5"; font.pixelSize: 14 }
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1b26"

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Atomic & Reliable"
                    font.pixelSize: 28
                    font.bold: true
                    color: "#f7768e"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Built on Fedora Atomic (bootc)"
                    font.pixelSize: 16
                    color: "#a9b1d6"
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Text { text: "• Immutable base system"; color: "#c0caf5"; font.pixelSize: 14 }
                    Text { text: "• Atomic updates with rollback"; color: "#c0caf5"; font.pixelSize: 14 }
                    Text { text: "• Container-native workflow"; color: "#c0caf5"; font.pixelSize: 14 }
                    Text { text: "• Always recoverable"; color: "#c0caf5"; font.pixelSize: 14 }
                }
            }
        }
    }
}
