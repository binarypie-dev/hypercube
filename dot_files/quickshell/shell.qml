//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications

import "modules/common" as Common
import "modules/bar" as Bar
import "modules/osd" as Osd
import "modules/sidebars" as Sidebars
import "modules/notifications" as NotificationsModule
import "modules/switcher" as Switcher
import "services" as Services

ShellRoot {
    id: root

    Component.onCompleted: {
        console.log("Hypercube Shell starting...")
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
    // Example: qs ipc call shell toggleSidebarLeft
    IpcHandler {
        target: "shell"

        function toggleSidebarLeft() {
            // Left sidebar always opens on leftmost screen with apps view
            GlobalStates.activeScreen = GlobalStates.leftmostScreen || Quickshell.screens[0]
            if (GlobalStates.sidebarLeftOpen && GlobalStates.sidebarLeftView === "apps") {
                // Already showing apps, close it
                GlobalStates.sidebarLeftOpen = false
            } else {
                // Open and switch to apps view
                GlobalStates.sidebarLeftView = "apps"
                GlobalStates.sidebarLeftOpen = true
            }
        }

        function toggleSidebarRight() {
            // Right sidebar always opens on rightmost screen
            GlobalStates.activeScreen = GlobalStates.rightmostScreen || Quickshell.screens[0]
            GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
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

                // Click catcher for sidebars (on ALL screens when any sidebar is open)
                Loader {
                    active: GlobalStates.sidebarLeftOpen || GlobalStates.sidebarRightOpen
                    sourceComponent: Common.ClickCatcher {
                        targetScreen: screenRoot.screen
                        onClicked: GlobalStates.closeAll()
                    }
                }

                // Left sidebar (only on leftmost screen)
                Loader {
                    active: GlobalStates.isLeftmostScreen(screenRoot.screen)
                    sourceComponent: Sidebars.SidebarLeft {
                        targetScreen: screenRoot.screen
                    }
                }

                // Right sidebar (only on rightmost screen)
                Loader {
                    active: GlobalStates.isRightmostScreen(screenRoot.screen)
                    sourceComponent: Sidebars.SidebarRight {
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

                // App switcher (on the output that has keyboard focus — niri
                // only focuses layer surfaces on its active output)
                Loader {
                    active: Services.Windows.switcherScreen === screenRoot.screen
                    sourceComponent: Switcher.AppSwitcher {
                        targetScreen: screenRoot.screen
                    }
                }
            }
        }
    }
}
