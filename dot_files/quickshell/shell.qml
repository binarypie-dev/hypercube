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
import "services" as Services

ShellRoot {
    id: root

    Component.onCompleted: {
        console.log("Hypercube Shell starting...")
        Common.Config.load()
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
            // Left sidebar always opens on leftmost screen
            GlobalStates.activeScreen = GlobalStates.leftmostScreen || Quickshell.screens[0]
            GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen
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

                // Click catcher for sidebars (on appropriate screens)
                // Left sidebar click catcher (only on leftmost screen)
                Loader {
                    active: GlobalStates.isLeftmostScreen(screenRoot.screen) && GlobalStates.sidebarLeftOpen
                    sourceComponent: Common.ClickCatcher {
                        targetScreen: screenRoot.screen
                        onClicked: GlobalStates.closeAll()
                    }
                }

                // Right sidebar click catcher (only on rightmost screen)
                Loader {
                    active: GlobalStates.isRightmostScreen(screenRoot.screen) && GlobalStates.sidebarRightOpen
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
            }
        }
    }
}
