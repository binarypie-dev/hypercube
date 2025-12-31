import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

import "../common" as Common

// First-boot welcome wizard for user creation and initial setup
PanelWindow {
    id: root

    required property var screen

    // Full screen overlay
    anchors.fill: true

    color: Common.Appearance.m3colors.background

    visible: false  // Controlled externally

    property int currentStep: 0
    property int totalSteps: 4

    // User creation data
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
        spacing: Common.Appearance.spacing.xlarge

        // Header
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Common.Appearance.spacing.small

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Welcome to Hypercube"
                font.family: Common.Appearance.fonts.title
                font.pixelSize: Common.Appearance.fontSize.display
                font.weight: Font.Medium
                color: Common.Appearance.m3colors.primary
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: getStepTitle()
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.large
                color: Common.Appearance.m3colors.onSurfaceVariant
            }
        }

        // Progress indicator
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Common.Appearance.spacing.small

            Repeater {
                model: totalSteps

                Rectangle {
                    width: 40
                    height: 4
                    radius: 2
                    color: index <= currentStep
                        ? Common.Appearance.m3colors.primary
                        : Common.Appearance.m3colors.surfaceVariant
                }
            }
        }

        // Content area
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 320
            radius: Common.Appearance.rounding.xlarge
            color: Common.Appearance.m3colors.surfaceVariant

            Loader {
                anchors.fill: parent
                anchors.margins: Common.Appearance.spacing.xlarge
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
            font.family: Common.Appearance.fonts.main
            font.pixelSize: Common.Appearance.fontSize.normal
            color: Common.Appearance.m3colors.error
        }

        // Navigation buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: Common.Appearance.spacing.medium

            // Back button
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
                    radius: Common.Appearance.rounding.large
                    color: parent.containsMouse
                        ? Common.Appearance.m3colors.surfaceVariant
                        : "transparent"
                    border.width: 1
                    border.color: Common.Appearance.m3colors.outline
                }

                Text {
                    anchors.centerIn: parent
                    text: "Back"
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.normal
                    color: Common.Appearance.m3colors.onSurface
                }
            }

            Item { Layout.fillWidth: true }

            // Next/Create button
            MouseArea {
                Layout.preferredWidth: currentStep === totalSteps - 1 ? 160 : 100
                Layout.preferredHeight: 44
                cursorShape: Qt.PointingHandCursor
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
                    radius: Common.Appearance.rounding.large
                    color: parent.containsMouse
                        ? Qt.darker(Common.Appearance.m3colors.primary, 1.1)
                        : Common.Appearance.m3colors.primary
                }

                Text {
                    anchors.centerIn: parent
                    text: currentStep === totalSteps - 1 ? "Create Account" : "Next"
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.normal
                    font.weight: Font.Medium
                    color: Common.Appearance.m3colors.onPrimary
                }
            }
        }
    }

    // Step 1: Username
    Component {
        id: usernameStep

        ColumnLayout {
            spacing: Common.Appearance.spacing.large

            Text {
                Layout.fillWidth: true
                text: "Let's create your account. First, choose a username."
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.normal
                color: Common.Appearance.m3colors.onSurface
                wrapMode: Text.WordWrap
            }

            WizardInput {
                id: usernameInput
                Layout.fillWidth: true
                label: "Username"
                placeholder: "Enter username"
                text: username
                onTextChanged: username = text

                Component.onCompleted: forceActiveFocus()
            }

            WizardInput {
                Layout.fillWidth: true
                label: "Full Name (optional)"
                placeholder: "Enter your full name"
                text: fullName
                onTextChanged: fullName = text
            }

            Text {
                Layout.fillWidth: true
                text: "Username must be lowercase, start with a letter, and contain only letters, numbers, underscores, or hyphens."
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.m3colors.onSurfaceVariant
                wrapMode: Text.WordWrap
            }
        }
    }

    // Step 2: Password
    Component {
        id: passwordStep

        ColumnLayout {
            spacing: Common.Appearance.spacing.large

            Text {
                Layout.fillWidth: true
                text: "Create a secure password for your account."
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.normal
                color: Common.Appearance.m3colors.onSurface
                wrapMode: Text.WordWrap
            }

            WizardInput {
                id: passwordInput
                Layout.fillWidth: true
                label: "Password"
                placeholder: "Enter password"
                isPassword: true
                text: password
                onTextChanged: password = text

                Component.onCompleted: forceActiveFocus()
            }

            WizardInput {
                Layout.fillWidth: true
                label: "Confirm Password"
                placeholder: "Confirm password"
                isPassword: true
                text: passwordConfirm
                onTextChanged: passwordConfirm = text
            }

            Text {
                Layout.fillWidth: true
                text: "Password must be at least 8 characters."
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.m3colors.onSurfaceVariant
                wrapMode: Text.WordWrap
            }
        }
    }

    // Step 3: Theme selection
    Component {
        id: themeStep

        ColumnLayout {
            spacing: Common.Appearance.spacing.large

            Text {
                Layout.fillWidth: true
                text: "Choose your preferred appearance. You can change this later in Settings."
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.normal
                color: Common.Appearance.m3colors.onSurface
                wrapMode: Text.WordWrap
            }

            // Dark/Light mode
            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.medium

                ThemeOption {
                    Layout.fillWidth: true
                    label: "Dark"
                    icon: Common.Icons.icons.night
                    selected: selectedDarkMode
                    onClicked: selectedDarkMode = true
                }

                ThemeOption {
                    Layout.fillWidth: true
                    label: "Light"
                    icon: Common.Icons.icons.sunny
                    selected: !selectedDarkMode
                    onClicked: selectedDarkMode = false
                }
            }

            Text {
                Layout.topMargin: Common.Appearance.spacing.medium
                text: "Accent Color"
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.small
                font.weight: Font.Medium
                color: Common.Appearance.m3colors.onSurfaceVariant
            }

            // Accent colors
            RowLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.small

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
                            radius: Common.Appearance.rounding.full
                            color: modelData.color

                            Rectangle {
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                radius: 10
                                visible: selectedAccent === modelData.id
                                color: "white"

                                Common.Icon {
                                    anchors.centerIn: parent
                                    name: Common.Icons.icons.check
                                    size: 14
                                    color: modelData.color
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Step 4: Confirmation
    Component {
        id: confirmStep

        ColumnLayout {
            spacing: Common.Appearance.spacing.large

            Text {
                Layout.fillWidth: true
                text: "Review your settings and create your account."
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.normal
                color: Common.Appearance.m3colors.onSurface
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: summaryColumn.implicitHeight + Common.Appearance.spacing.large * 2
                radius: Common.Appearance.rounding.large
                color: Common.Appearance.surfaceLayer(1)

                ColumnLayout {
                    id: summaryColumn
                    anchors.fill: parent
                    anchors.margins: Common.Appearance.spacing.large
                    spacing: Common.Appearance.spacing.medium

                    SummaryRow { label: "Username"; value: username }
                    SummaryRow { label: "Full Name"; value: fullName || "(not set)" }
                    SummaryRow { label: "Theme"; value: selectedDarkMode ? "Dark" : "Light" }
                    SummaryRow { label: "Accent"; value: selectedAccent.charAt(0).toUpperCase() + selectedAccent.slice(1) }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Your account will be added to the 'wheel' group for administrator access."
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.m3colors.onSurfaceVariant
                wrapMode: Text.WordWrap
            }
        }
    }

    // Helper components
    component WizardInput: ColumnLayout {
        property string label: ""
        property string placeholder: ""
        property bool isPassword: false
        property alias text: inputField.text

        signal textChanged()

        spacing: Common.Appearance.spacing.tiny

        function forceActiveFocus() {
            inputField.forceActiveFocus()
        }

        Text {
            text: label
            font.family: Common.Appearance.fonts.main
            font.pixelSize: Common.Appearance.fontSize.small
            font.weight: Font.Medium
            color: Common.Appearance.m3colors.onSurfaceVariant
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: Common.Appearance.rounding.medium
            color: Common.Appearance.surfaceLayer(1)
            border.width: inputField.activeFocus ? 2 : 1
            border.color: inputField.activeFocus
                ? Common.Appearance.m3colors.primary
                : Common.Appearance.m3colors.outline

            TextInput {
                id: inputField
                anchors.fill: parent
                anchors.margins: Common.Appearance.spacing.medium
                font.family: Common.Appearance.fonts.main
                font.pixelSize: Common.Appearance.fontSize.normal
                color: Common.Appearance.m3colors.onSurface
                echoMode: isPassword ? TextInput.Password : TextInput.Normal
                clip: true

                onTextChanged: parent.parent.textChanged()

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: placeholder
                    font: inputField.font
                    color: Common.Appearance.m3colors.onSurfaceVariant
                    visible: !inputField.text && !inputField.activeFocus
                }
            }
        }
    }

    component ThemeOption: MouseArea {
        property string label: ""
        property string icon: ""
        property bool selected: false

        Layout.preferredHeight: 80
        cursorShape: Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: Common.Appearance.rounding.large
            color: selected
                ? Common.Appearance.m3colors.primaryContainer
                : Common.Appearance.surfaceLayer(1)
            border.width: selected ? 2 : 1
            border.color: selected
                ? Common.Appearance.m3colors.primary
                : Common.Appearance.m3colors.outline

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Common.Appearance.spacing.small

                Common.Icon {
                    Layout.alignment: Qt.AlignHCenter
                    name: icon
                    size: Common.Appearance.sizes.iconXLarge
                    color: selected
                        ? Common.Appearance.m3colors.onPrimaryContainer
                        : Common.Appearance.m3colors.onSurface
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: label
                    font.family: Common.Appearance.fonts.main
                    font.pixelSize: Common.Appearance.fontSize.normal
                    color: selected
                        ? Common.Appearance.m3colors.onPrimaryContainer
                        : Common.Appearance.m3colors.onSurface
                }
            }
        }
    }

    component SummaryRow: RowLayout {
        property string label: ""
        property string value: ""

        Layout.fillWidth: true

        Text {
            text: label
            font.family: Common.Appearance.fonts.main
            font.pixelSize: Common.Appearance.fontSize.normal
            color: Common.Appearance.m3colors.onSurfaceVariant
        }

        Item { Layout.fillWidth: true }

        Text {
            text: value
            font.family: Common.Appearance.fonts.main
            font.pixelSize: Common.Appearance.fontSize.normal
            font.weight: Font.Medium
            color: Common.Appearance.m3colors.onSurface
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

            case 2:
                return true

            case 3:
                return true

            default:
                return true
        }
    }

    function createUser() {
        errorMessage = ""

        // Create user via pkexec (polkit)
        userCreateProcess.running = true
    }

    Process {
        id: userCreateProcess
        command: ["pkexec", "sh", "-c",
            "useradd -m -G wheel -c '" + (fullName || username) + "' '" + username + "' && " +
            "echo '" + username + ":" + password + "' | chpasswd"
        ]

        running: false
        onExited: {
            if (exitCode === 0) {
                // Save theme preferences
                Common.Config.darkMode = selectedDarkMode
                Common.Config.accentColor = selectedAccent
                Common.Config.save()

                // Hide wizard and signal completion
                root.visible = false
                userCreated()
            } else {
                errorMessage = "Failed to create user. Please try again."
            }
        }
    }

    signal userCreated()
}
