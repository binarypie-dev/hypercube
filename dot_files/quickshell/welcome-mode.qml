// Standalone welcome mode for first-boot wizard
// This runs independently of the main shell for user creation

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root

    // Welcome wizard runs on all screens, full screen
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: welcomeWindow
                required property var modelData
                property var screen: modelData

                anchors.fill: true
                color: "#1a1b26"  // Tokyonight background

                // Only show wizard on primary screen
                property bool isPrimary: screen === Quickshell.screens[0]

                // Background for non-primary screens
                Rectangle {
                    anchors.fill: parent
                    visible: !isPrimary
                    color: "#1a1b26"

                    Text {
                        anchors.centerIn: parent
                        text: "Hypercube"
                        font.pixelSize: 48
                        font.weight: Font.Medium
                        color: "#7aa2f7"
                        opacity: 0.3
                    }
                }

                // Wizard on primary screen
                Loader {
                    anchors.fill: parent
                    active: isPrimary
                    sourceComponent: WelcomeWizard {}
                }
            }
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

        property int currentStep: 0
        property int totalSteps: 4

        // User data
        property string username: ""
        property string fullName: ""
        property string password: ""
        property string passwordConfirm: ""
        property string errorMessage: ""

        // Theme preferences
        property bool selectedDarkMode: true
        property string selectedAccent: "blue"

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
                    text: getStepTitle()
                    font.pixelSize: 18
                    color: subtextColor
                }
            }

            // Progress indicator
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                Repeater {
                    model: totalSteps

                    Rectangle {
                        width: 40
                        height: 4
                        radius: 2
                        color: index <= currentStep ? primaryColor : surfaceColor
                    }
                }
            }

            // Content area
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 320
                radius: 16
                color: surfaceColor

                Loader {
                    anchors.fill: parent
                    anchors.margins: 24
                    sourceComponent: {
                        switch (currentStep) {
                            case 0: return usernameStep
                            case 1: return passwordStep
                            case 2: return themeStep
                            case 3: return confirmStep
                            default: return usernameStep
                        }
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

            // Navigation buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                MouseArea {
                    visible: currentStep > 0
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 44
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        errorMessage = ""
                        currentStep--
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: "transparent"
                        border.width: 1
                        border.color: subtextColor
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Back"
                        font.pixelSize: 14
                        color: textColor
                    }
                }

                Item { Layout.fillWidth: true }

                MouseArea {
                    Layout.preferredWidth: currentStep === totalSteps - 1 ? 160 : 100
                    Layout.preferredHeight: 44
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (validateStep()) {
                            if (currentStep === totalSteps - 1) {
                                createUser()
                            } else {
                                currentStep++
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: parent.containsMouse ? Qt.darker(primaryColor, 1.1) : primaryColor
                    }

                    Text {
                        anchors.centerIn: parent
                        text: currentStep === totalSteps - 1 ? "Create Account" : "Next"
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: bgColor
                    }
                }
            }
        }

        // Step 1: Username
        Component {
            id: usernameStep

            ColumnLayout {
                spacing: 24

                Text {
                    Layout.fillWidth: true
                    text: "Let's create your account. First, choose a username."
                    font.pixelSize: 14
                    color: textColor
                    wrapMode: Text.WordWrap
                }

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
                        Layout.preferredHeight: 48
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
                        Layout.preferredHeight: 48
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

                Text {
                    Layout.fillWidth: true
                    text: "Username must be lowercase, start with a letter, and contain only letters, numbers, underscores, or hyphens."
                    font.pixelSize: 12
                    color: subtextColor
                    wrapMode: Text.WordWrap
                }
            }
        }

        // Step 2: Password
        Component {
            id: passwordStep

            ColumnLayout {
                spacing: 24

                Text {
                    Layout.fillWidth: true
                    text: "Create a secure password for your account."
                    font.pixelSize: 14
                    color: textColor
                    wrapMode: Text.WordWrap
                }

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
                        Layout.preferredHeight: 48
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
                            Component.onCompleted: forceActiveFocus()

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
                        Layout.preferredHeight: 48
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
                    text: "Password must be at least 8 characters."
                    font.pixelSize: 12
                    color: subtextColor
                    wrapMode: Text.WordWrap
                }
            }
        }

        // Step 3: Theme
        Component {
            id: themeStep

            ColumnLayout {
                spacing: 24

                Text {
                    Layout.fillWidth: true
                    text: "Choose your preferred appearance. You can change this later in Settings."
                    font.pixelSize: 14
                    color: textColor
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    MouseArea {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        cursorShape: Qt.PointingHandCursor
                        onClicked: selectedDarkMode = true

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: selectedDarkMode ? "#3d59a1" : bgColor
                            border.width: selectedDarkMode ? 2 : 1
                            border.color: selectedDarkMode ? primaryColor : subtextColor

                            Column {
                                anchors.centerIn: parent
                                spacing: 8

                                Text { text: "nights_stay"; font.family: "Material Symbols Rounded"; font.pixelSize: 32; color: textColor; anchors.horizontalCenter: parent.horizontalCenter }
                                Text { text: "Dark"; font.pixelSize: 14; color: textColor; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                        }
                    }

                    MouseArea {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        cursorShape: Qt.PointingHandCursor
                        onClicked: selectedDarkMode = false

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: !selectedDarkMode ? "#3d59a1" : bgColor
                            border.width: !selectedDarkMode ? 2 : 1
                            border.color: !selectedDarkMode ? primaryColor : subtextColor

                            Column {
                                anchors.centerIn: parent
                                spacing: 8

                                Text { text: "sunny"; font.family: "Material Symbols Rounded"; font.pixelSize: 32; color: textColor; anchors.horizontalCenter: parent.horizontalCenter }
                                Text { text: "Light"; font.pixelSize: 14; color: textColor; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                        }
                    }
                }

                Text {
                    text: "Accent Color"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: subtextColor
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "blue", color: "#7aa2f7" },
                            { id: "green", color: "#9ece6a" },
                            { id: "purple", color: "#bb9af7" },
                            { id: "orange", color: "#ff9e64" },
                            { id: "red", color: "#f7768e" },
                            { id: "cyan", color: "#7dcfff" }
                        ]

                        delegate: MouseArea {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            cursorShape: Qt.PointingHandCursor
                            onClicked: selectedAccent = modelData.id

                            Rectangle {
                                anchors.fill: parent
                                radius: 24
                                color: modelData.color

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 20
                                    height: 20
                                    radius: 10
                                    visible: selectedAccent === modelData.id
                                    color: "white"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "check"
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 14
                                        color: modelData.color
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Step 4: Confirm
        Component {
            id: confirmStep

            ColumnLayout {
                spacing: 24

                Text {
                    Layout.fillWidth: true
                    text: "Review your settings and create your account."
                    font.pixelSize: 14
                    color: textColor
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: summaryCol.implicitHeight + 32
                    radius: 12
                    color: bgColor

                    Column {
                        id: summaryCol
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Row {
                            width: parent.width
                            Text { text: "Username"; font.pixelSize: 14; color: subtextColor; width: parent.width / 2 }
                            Text { text: username; font.pixelSize: 14; font.weight: Font.Medium; color: textColor }
                        }
                        Row {
                            width: parent.width
                            Text { text: "Full Name"; font.pixelSize: 14; color: subtextColor; width: parent.width / 2 }
                            Text { text: fullName || "(not set)"; font.pixelSize: 14; font.weight: Font.Medium; color: textColor }
                        }
                        Row {
                            width: parent.width
                            Text { text: "Theme"; font.pixelSize: 14; color: subtextColor; width: parent.width / 2 }
                            Text { text: selectedDarkMode ? "Dark" : "Light"; font.pixelSize: 14; font.weight: Font.Medium; color: textColor }
                        }
                        Row {
                            width: parent.width
                            Text { text: "Accent"; font.pixelSize: 14; color: subtextColor; width: parent.width / 2 }
                            Text { text: selectedAccent.charAt(0).toUpperCase() + selectedAccent.slice(1); font.pixelSize: 14; font.weight: Font.Medium; color: textColor }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Your account will be added to the 'wheel' group for administrator access."
                    font.pixelSize: 12
                    color: subtextColor
                    wrapMode: Text.WordWrap
                }
            }
        }

        function getStepTitle(): string {
            switch (currentStep) {
                case 0: return "Create Your Account"
                case 1: return "Set Your Password"
                case 2: return "Choose Your Theme"
                case 3: return "Confirm Your Settings"
                default: return ""
            }
        }

        function validateStep(): bool {
            errorMessage = ""

            switch (currentStep) {
                case 0:
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
                    return true

                case 1:
                    if (!password || password.length < 8) {
                        errorMessage = "Password must be at least 8 characters"
                        return false
                    }
                    if (password !== passwordConfirm) {
                        errorMessage = "Passwords do not match"
                        return false
                    }
                    return true

                default:
                    return true
            }
        }

        function createUser() {
            errorMessage = ""
            userCreateProcess.running = true
        }

        Process {
            id: userCreateProcess
            command: ["sh", "-c",
                "useradd -m -G wheel -c '" + (fullName || username) + "' '" + username + "' && " +
                "echo '" + username + ":" + password + "' | chpasswd && " +
                // Save theme config for the new user
                "mkdir -p /home/" + username + "/.config/hypercube && " +
                "echo '{\"appearance\":{\"darkMode\":" + (selectedDarkMode ? "true" : "false") + ",\"accentColor\":\"" + selectedAccent + "\"}}' > /home/" + username + "/.config/hypercube/shell.json && " +
                "chown -R " + username + ":" + username + " /home/" + username + "/.config"
            ]

            running: false
            onExited: {
                if (exitCode === 0) {
                    // Exit quickshell, which will cause Hyprland to exit
                    Qt.quit()
                } else {
                    errorMessage = "Failed to create user. Exit code: " + exitCode
                }
            }
        }
    }
}
