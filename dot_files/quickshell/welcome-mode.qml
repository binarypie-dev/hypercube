// Standalone welcome mode for first-boot wizard
// This runs independently of the main shell for user creation

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Window
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    // Simple fullscreen window for cage compositor
    Window {
        id: welcomeWindow
        visible: true
        visibility: Window.FullScreen
        color: "#1a1b26"  // Tokyonight background
        title: "Hypercube Setup"

        // Wizard content
        WelcomeWizard {
            anchors.fill: parent
        }
    }

    // Welcome Wizard Component
    component WelcomeWizard: Item {
        anchors.fill: parent

        // Theme colors (Tokyonight)
        readonly property color bgColor: "#1a1b26"
        readonly property color surfaceColor: "#24283b"
        readonly property color primaryColor: "#7aa2f7"
        readonly property color textColor: "#c0caf5"
        readonly property color subtextColor: "#a9b1d6"
        readonly property color errorColor: "#f7768e"

        // User data
        property string username: ""
        property string fullName: ""
        property string password: ""
        property string passwordConfirm: ""
        property string errorMessage: ""
        property bool isCreating: false

        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(parent.width - 100, 500)
            spacing: 32

            // Header
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Welcome to Hypercube"
                    font.pixelSize: 36
                    font.weight: Font.Medium
                    color: primaryColor
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Create Your Account"
                    font.pixelSize: 18
                    color: subtextColor
                }
            }

            // Content area
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 380
                radius: 16
                color: surfaceColor

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16

                    Text {
                        Layout.fillWidth: true
                        text: "Let's create your account."
                        font.pixelSize: 14
                        color: textColor
                        wrapMode: Text.WordWrap
                    }

                    // Username field
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "Username"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: subtextColor
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            radius: 8
                            color: bgColor
                            border.width: usernameInput.activeFocus ? 2 : 1
                            border.color: usernameInput.activeFocus ? primaryColor : subtextColor

                            TextInput {
                                id: usernameInput
                                anchors.fill: parent
                                anchors.margins: 12
                                font.pixelSize: 14
                                color: textColor
                                clip: true
                                text: username
                                onTextChanged: username = text
                                activeFocusOnTab: true
                                KeyNavigation.tab: fullNameInput
                                Component.onCompleted: forceActiveFocus()

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Enter username"
                                    font: usernameInput.font
                                    color: subtextColor
                                    visible: !usernameInput.text && !usernameInput.activeFocus
                                }
                            }
                        }
                    }

                    // Full Name field
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "Full Name (optional)"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: subtextColor
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            radius: 8
                            color: bgColor
                            border.width: fullNameInput.activeFocus ? 2 : 1
                            border.color: fullNameInput.activeFocus ? primaryColor : subtextColor

                            TextInput {
                                id: fullNameInput
                                anchors.fill: parent
                                anchors.margins: 12
                                font.pixelSize: 14
                                color: textColor
                                clip: true
                                text: fullName
                                onTextChanged: fullName = text
                                activeFocusOnTab: true
                                KeyNavigation.tab: passwordInput
                                KeyNavigation.backtab: usernameInput

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Enter your full name"
                                    font: fullNameInput.font
                                    color: subtextColor
                                    visible: !fullNameInput.text && !fullNameInput.activeFocus
                                }
                            }
                        }
                    }

                    // Password field
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "Password"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: subtextColor
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            radius: 8
                            color: bgColor
                            border.width: passwordInput.activeFocus ? 2 : 1
                            border.color: passwordInput.activeFocus ? primaryColor : subtextColor

                            TextInput {
                                id: passwordInput
                                anchors.fill: parent
                                anchors.margins: 12
                                font.pixelSize: 14
                                color: textColor
                                clip: true
                                echoMode: TextInput.Password
                                text: password
                                onTextChanged: password = text
                                activeFocusOnTab: true
                                KeyNavigation.tab: confirmInput
                                KeyNavigation.backtab: fullNameInput

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Enter password"
                                    font: passwordInput.font
                                    color: subtextColor
                                    visible: !passwordInput.text && !passwordInput.activeFocus
                                }
                            }
                        }
                    }

                    // Confirm Password field
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "Confirm Password"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: subtextColor
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            radius: 8
                            color: bgColor
                            border.width: confirmInput.activeFocus ? 2 : 1
                            border.color: confirmInput.activeFocus ? primaryColor : subtextColor

                            TextInput {
                                id: confirmInput
                                anchors.fill: parent
                                anchors.margins: 12
                                font.pixelSize: 14
                                color: textColor
                                clip: true
                                echoMode: TextInput.Password
                                text: passwordConfirm
                                onTextChanged: passwordConfirm = text
                                activeFocusOnTab: true
                                KeyNavigation.backtab: passwordInput

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Confirm password"
                                    font: confirmInput.font
                                    color: subtextColor
                                    visible: !confirmInput.text && !confirmInput.activeFocus
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Username: lowercase, starts with letter. Password: at least 8 characters."
                        font.pixelSize: 11
                        color: subtextColor
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // Error message
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: errorMessage !== ""
                text: errorMessage
                font.pixelSize: 14
                color: errorColor
            }

            // Create Account button
            MouseArea {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 180
                Layout.preferredHeight: 48
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                enabled: !isCreating
                onClicked: {
                    if (validateInput()) {
                        createUser()
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: isCreating ? Qt.darker(primaryColor, 1.3) : parent.containsMouse ? Qt.darker(primaryColor, 1.1) : primaryColor
                }

                Text {
                    anchors.centerIn: parent
                    text: isCreating ? "Creating..." : "Create Account"
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    color: bgColor
                }
            }

            // Info text
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Your account will have administrator access."
                font.pixelSize: 12
                color: subtextColor
            }
        }

        function validateInput(): bool {
            errorMessage = ""

            if (!username || username.trim() === "") {
                errorMessage = "Username is required"
                return false
            }
            if (!/^[a-z_][a-z0-9_-]*$/.test(username)) {
                errorMessage = "Invalid username format"
                return false
            }
            if (username.length > 32) {
                errorMessage = "Username too long (max 32 characters)"
                return false
            }
            if (!password || password.length < 8) {
                errorMessage = "Password must be at least 8 characters"
                return false
            }
            if (password !== passwordConfirm) {
                errorMessage = "Passwords do not match"
                return false
            }
            return true
        }

        function createUser() {
            if (isCreating) return
            isCreating = true
            errorMessage = ""
            userCreateProcess.running = true
        }

        // Escape single quotes in strings for shell safety
        function shellEscape(str: string): string {
            return str.replace(/'/g, "'\\''")
        }

        Process {
            id: userCreateProcess
            // Runs as root via greetd initial_session
            // After creating user, remove initial_session from greetd config to prevent wizard on next boot
            command: ["sh", "-c",
                "useradd -m -G wheel -c '" + shellEscape(fullName || username) + "' '" + shellEscape(username) + "' && " +
                "echo '" + shellEscape(username) + ":" + shellEscape(password) + "' | chpasswd && " +
                // Remove initial_session block from greetd config
                "sed -i '/^\\[initial_session\\]/,/^\\[/{ /^\\[initial_session\\]/d; /^\\[/!d; }' /etc/greetd/config.toml && " +
                // Also handle case where initial_session is at end of file (no following section)
                "sed -i '/^\\[initial_session\\]/,$d' /etc/greetd/config.toml"
            ]

            running: false
            onExited: (code, status) => {
                isCreating = false
                if (code === 0) {
                    // Success - exit to greetd login screen
                    Qt.quit()
                } else {
                    errorMessage = "Failed to create user (error " + code + "). Please try again."
                }
            }
        }

        // Allow exiting with Escape key
        Shortcut {
            sequence: "Escape"
            onActivated: {
                if (!isCreating) {
                    // Exit without creating user - greetd will show regreet
                    Qt.quit()
                }
            }
        }
    }
}
