pragma Singleton

import QtQuick

// Material Design 3 theming system with Tokyonight defaults
QtObject {
    id: root

    // Dark mode toggle
    property bool darkMode: true

    // Tokyonight color palette mapped to Material Design 3 roles
    readonly property var m3colors: darkMode ? darkPalette : lightPalette

    readonly property var darkPalette: ({
        // Primary colors (Tokyonight blue)
        primary: "#7aa2f7",
        onPrimary: "#1a1b26",
        primaryContainer: "#3d59a1",
        onPrimaryContainer: "#c0caf5",

        // Secondary colors (Tokyonight green)
        secondary: "#9ece6a",
        onSecondary: "#1a1b26",
        secondaryContainer: "#4a5e3a",
        onSecondaryContainer: "#c0caf5",

        // Tertiary colors (Tokyonight purple)
        tertiary: "#bb9af7",
        onTertiary: "#1a1b26",
        tertiaryContainer: "#6a4c93",
        onTertiaryContainer: "#c0caf5",

        // Error colors (Tokyonight red)
        error: "#f7768e",
        onError: "#1a1b26",
        errorContainer: "#8c4351",
        onErrorContainer: "#ffc0c8",

        // Background and surface
        background: "#1a1b26",
        onBackground: "#c0caf5",
        surface: "#1a1b26",
        onSurface: "#c0caf5",
        surfaceVariant: "#24283b",
        onSurfaceVariant: "#a9b1d6",

        // Outline
        outline: "#33467c",
        outlineVariant: "#292e42",

        // Inverse
        inverseSurface: "#c0caf5",
        inverseOnSurface: "#1a1b26",
        inversePrimary: "#3d59a1",

        // Additional Tokyonight colors
        cyan: "#7dcfff",
        orange: "#ff9e64",
        yellow: "#e0af68",
        magenta: "#ff007c",
        teal: "#1abc9c",
        comment: "#565f89"
    })

    readonly property var lightPalette: ({
        // Primary colors
        primary: "#3d59a1",
        onPrimary: "#ffffff",
        primaryContainer: "#d0e4ff",
        onPrimaryContainer: "#001d36",

        // Secondary colors
        secondary: "#4a5e3a",
        onSecondary: "#ffffff",
        secondaryContainer: "#cce8b5",
        onSecondaryContainer: "#0e2000",

        // Tertiary colors
        tertiary: "#6a4c93",
        onTertiary: "#ffffff",
        tertiaryContainer: "#eddcff",
        onTertiaryContainer: "#25005a",

        // Error colors
        error: "#ba1a1a",
        onError: "#ffffff",
        errorContainer: "#ffdad6",
        onErrorContainer: "#410002",

        // Background and surface
        background: "#d5d6db",
        onBackground: "#343338",
        surface: "#f8f9ff",
        onSurface: "#1a1b26",
        surfaceVariant: "#e0e2ec",
        onSurfaceVariant: "#44464f",

        // Outline
        outline: "#74777f",
        outlineVariant: "#c4c6d0",

        // Inverse
        inverseSurface: "#2f3033",
        inverseOnSurface: "#f1f0f4",
        inversePrimary: "#9ecaff",

        // Additional colors
        cyan: "#0891b2",
        orange: "#c2410c",
        yellow: "#a16207",
        magenta: "#be185d",
        teal: "#0d9488",
        comment: "#6b7280"
    })

    // Surface layers (MD3 elevation)
    function surfaceLayer(level: int): color {
        const base = m3colors.surface
        const tint = m3colors.primary
        const alphas = [0, 0.05, 0.08, 0.11, 0.12, 0.14]
        const alpha = alphas[Math.min(level, 5)]
        return Qt.tint(base, Qt.rgba(
            parseInt(tint.slice(1, 3), 16) / 255,
            parseInt(tint.slice(3, 5), 16) / 255,
            parseInt(tint.slice(5, 7), 16) / 255,
            alpha
        ))
    }

    // Animation durations
    readonly property var animation: ({
        // Expressive animations (spatial)
        expressiveFast: 200,
        expressive: 350,
        expressiveSlow: 500,

        // Emphasized animations
        emphasized: 500,
        emphasizedAccel: 200,
        emphasizedDecel: 400,

        // Standard animations
        standard: 300,
        standardAccel: 200,
        standardDecel: 300
    })

    // Easing curves
    readonly property var easing: ({
        emphasized: Easing.BezierSpline,
        emphasizedParams: [0.2, 0, 0, 1],
        standard: Easing.OutCubic,
        decelerate: Easing.OutQuart,
        accelerate: Easing.InQuart
    })

    // Typography
    readonly property var fonts: ({
        main: "JetBrains Mono",
        title: "JetBrains Mono",
        mono: "JetBrains Mono"
    })

    readonly property var fontSize: ({
        smallest: 10,
        small: 12,
        normal: 14,
        large: 16,
        title: 20,
        headline: 24,
        display: 32
    })

    // Spacing and rounding
    readonly property var spacing: ({
        tiny: 4,
        small: 8,
        medium: 12,
        large: 16,
        xlarge: 24,
        xxlarge: 32
    })

    readonly property var rounding: ({
        none: 0,
        small: 4,
        medium: 8,
        large: 12,
        xlarge: 16,
        full: 9999
    })

    // Component sizes
    readonly property var sizes: ({
        barHeight: 36,
        sidebarWidth: 380,
        osdWidth: 300,
        osdHeight: 48,
        launcherWidth: 600,
        launcherHeight: 500,
        notificationWidth: 380,
        iconSmall: 16,
        iconMedium: 20,
        iconLarge: 24,
        iconXLarge: 32
    })

    // Transparency settings
    property real panelOpacity: 0.85
    property real overlayOpacity: 0.95

    // Helper function to get contrasting text color
    function contrastText(backgroundColor: color): color {
        const r = backgroundColor.r
        const g = backgroundColor.g
        const b = backgroundColor.b
        const luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.5 ? m3colors.onBackground : m3colors.background
    }
}
