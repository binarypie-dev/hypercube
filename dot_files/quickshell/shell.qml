//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications

import "modules/bar" as Bar
import "modules/osd" as Osd
import "modules/hub" as Hub
import "modules/notifications" as NotificationsModule
import "services" as Services

ShellRoot {
    id: root

    Component.onCompleted: {
        console.log("Hypercube Shell starting...")
        // Background temperature watch (notifies when a sensor overheats)
        Services.Thermals.start()
    }

    // Hub always opens on the focused output on niri (it only gives
    // keyboard focus to layer surfaces there); otherwise keep it where it
    // last was, falling back to the first screen.
    function hubTarget() {
        return (Services.Compositor.isNiri && Services.Windows.focusedScreen)
            || GlobalStates.hubScreen || Quickshell.screens[0]
    }

    // The window switcher is the hub's "windows" tab: Mod+Tab starts a
    // switcher session (Services.Windows), which opens the hub there; ending
    // the session (select/cancel) closes it, and closing the hub or leaving
    // the tab cancels the session.
    Connections {
        target: Services.Windows
        function onSwitcherActiveChanged() {
            if (Services.Windows.switcherActive) {
                if (GlobalStates.hubOpen) {
                    GlobalStates.hubTab = "windows"
                } else {
                    GlobalStates.openHub(Services.Windows.switcherScreen, "windows")
                }
            } else if (GlobalStates.hubOpen && GlobalStates.hubTab === "windows") {
                GlobalStates.closeAll()
            }
        }
    }

    Connections {
        target: GlobalStates
        function onHubOpenChanged() {
            if (!GlobalStates.hubOpen && Services.Windows.switcherActive) {
                Services.Windows.cancelSwitcher()
            }
        }
        function onHubTabChanged() {
            if (GlobalStates.hubTab !== "windows" && Services.Windows.switcherActive) {
                Services.Windows.cancelSwitcher()
            }
        }
    }

    // Notification server
    NotificationServer {
        id: notificationServer
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: (notification) => {
            console.log("Notification received:", notification.summary)
            // Add to notification service and update count
            Services.Notifications.addNotification(notification)
            GlobalStates.unreadNotificationCount = Services.Notifications.unreadCount
        }
    }

    // IPC Handler for external commands
    // Use: qs ipc call shell <function> [args]
    // Example: qs ipc call shell toggleHub
    IpcHandler {
        target: "shell"

        // Mod+Space: open the hub on the apps tab, or close it if open
        function toggleHub() {
            if (GlobalStates.hubOpen) {
                GlobalStates.closeAll()
            } else {
                GlobalStates.openHub(root.hubTarget(), "apps")
            }
        }

        // Open the hub straight to a tab (apps, notifications, audio, network,
        // bluetooth, calendar, weather, power, updates); toggles if already there
        function toggleHubTab(tab: string) {
            GlobalStates.toggleHub(root.hubTarget(), tab)
        }

        // Compatibility aliases for older keybindings
        function toggleSidebarLeft() {
            toggleHubTab("apps")
        }

        function toggleSidebarRight() {
            toggleHubTab("notifications")
        }

        function showOsdVolume(value: real) {
            if (GlobalStates.activeScreen === null) {
                GlobalStates.activeScreen = Quickshell.screens[0]
            }
            GlobalStates.osdType = "volume"
            GlobalStates.osdValue = value
            GlobalStates.osdVisible = true
        }

        function showOsdBrightness(value: real) {
            if (GlobalStates.activeScreen === null) {
                GlobalStates.activeScreen = Quickshell.screens[0]
            }
            GlobalStates.osdType = "brightness"
            GlobalStates.osdValue = value
            GlobalStates.osdVisible = true
        }

        function showOsdMic(muted: bool) {
            if (GlobalStates.activeScreen === null) {
                GlobalStates.activeScreen = Quickshell.screens[0]
            }
            GlobalStates.osdType = "mic"
            GlobalStates.osdMuted = muted
            GlobalStates.osdVisible = true
        }

        function closeAll() {
            GlobalStates.closeAll()
            // Mod+Escape is the only escape hatch while the switcher holds the
            // keyboard: bare Escape can't be pressed without releasing Mod,
            // which commits the selection.
            Services.Windows.cancelSwitcher()
        }

        function startAppSwitcher() {
            Services.Windows.startSwitcher()
        }

        // next/prevWindow open the switcher on first press (already stepping in
        // the right direction) and cycle on every press after that.
        function nextWindow() {
            Services.Windows.nextWindow()
        }

        function prevWindow() {
            Services.Windows.prevWindow()
        }

        function selectWindow() {
            Services.Windows.selectWindow()
        }

        function cancelSwitcher() {
            Services.Windows.cancelSwitcher()
        }
    }

    // Screen-specific components
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Item {
                id: screenRoot
                required property var modelData
                property var screen: modelData

                // Top status bar (all screens)
                Bar.StatusBar {
                    targetScreen: screenRoot.screen
                }

                // OSD (on active screen, or primary if none set)
                Loader {
                    active: GlobalStates.activeScreen === screenRoot.screen ||
                            (GlobalStates.activeScreen === null && screenRoot.screen === Quickshell.screens[0])
                    sourceComponent: Osd.Osd {
                        targetScreen: screenRoot.screen
                    }
                }

                // Centered hub (single instance, on the screen it was opened on)
                Loader {
                    active: screenRoot.screen === (GlobalStates.hubScreen || Quickshell.screens[0])
                    sourceComponent: Hub.Hub {
                        targetScreen: screenRoot.screen
                    }
                }

                // Notification popups (on active screen, or primary if none set)
                Loader {
                    active: GlobalStates.activeScreen === screenRoot.screen ||
                            (GlobalStates.activeScreen === null && screenRoot.screen === Quickshell.screens[0])
                    sourceComponent: NotificationsModule.NotificationPopup {
                        targetScreen: screenRoot.screen
                    }
                }
            }
        }
    }
}
