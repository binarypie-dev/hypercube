pragma Singleton

import QtQuick
import Quickshell

// Which compositor the shell is running under.
// niri exports NIRI_SOCKET and Hyprland exports HYPRLAND_INSTANCE_SIGNATURE to
// the processes they spawn. Services use this to pick niri msg or hyprctl.
Singleton {
    id: root

    readonly property bool isNiri: !!Quickshell.env("NIRI_SOCKET")
    readonly property bool isHyprland: !isNiri

    readonly property string name: isNiri ? "niri" : "Hyprland"
}
