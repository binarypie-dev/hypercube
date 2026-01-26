pragma Singleton

import QtQuick

// Neovim/TUI-inspired theming system with Tokyo Night colors
QtObject {
    id: root

    // Dark mode toggle
    property bool darkMode: true

    // Tokyo Night color palette (direct colors, no MD3 abstraction)
    readonly property var colors: darkMode ? darkPalette : lightPalette

    readonly property var darkPalette: ({
        // Core background colors
        bg: "#1a1b26",
        bgDark: "#16161e",
        bgHighlight: "#292e42",
        bgVisual: "#33467c",

        // Foreground colors
        fg: "#c0caf5",
        fgDark: "#a9b1d6",
        fgGutter: "#3b4261",

        // Border colors
        border: "#414868",
        borderHighlight: "#7aa2f7",

        // Accent colors (matching Neovim Tokyo Night)
        blue: "#7aa2f7",
        cyan: "#7dcfff",
        green: "#9ece6a",
        magenta: "#bb9af7",
        orange: "#ff9e64",
        red: "#f7768e",
        yellow: "#e0af68",
        teal: "#1abc9c",

        // Semantic colors
        comment: "#565f89",
        error: "#f7768e",
        warning: "#e0af68",
        info: "#7dcfff",
        hint: "#1abc9c",

        // Git colors
        gitAdd: "#449dab",
        gitChange: "#6183bb",
        gitDelete: "#914c54",

        // Mode colors (like Neovim mode indicators)
        modeNormal: "#7aa2f7",
        modeInsert: "#9ece6a",
        modeVisual: "#bb9af7",
        modeReplace: "#f7768e",
        modeCommand: "#e0af68"
    })

    readonly property var lightPalette: ({
        // Core background colors
        bg: "#d5d6db",
        bgDark: "#cbccd1",
        bgHighlight: "#b7b8bd",
        bgVisual: "#99a0b5",

        // Foreground colors
        fg: "#343b58",
        fgDark: "#4c5372",
        fgGutter: "#9699a3",

        // Border colors
        border: "#9699a3",
        borderHighlight: "#2e7de9",

        // Accent colors
        blue: "#2e7de9",
        cyan: "#007197",
        green: "#587539",
        magenta: "#9854f1",
        orange: "#b15c00",
        red: "#f52a65",
        yellow: "#8c6c3e",
        teal: "#118c74",

        // Semantic colors
        comment: "#848cb5",
        error: "#f52a65",
        warning: "#8c6c3e",
        info: "#007197",
        hint: "#118c74",

        // Git colors
        gitAdd: "#387068",
        gitChange: "#506d9b",
        gitDelete: "#c47981",

        // Mode colors
        modeNormal: "#2e7de9",
        modeInsert: "#587539",
        modeVisual: "#9854f1",
        modeReplace: "#f52a65",
        modeCommand: "#8c6c3e"
    })

    // No surface layer tinting - just use flat colors with optional transparency
    function surfaceColor(level: int): color {
        switch (level) {
            case 0: return colors.bg
            case 1: return colors.bgDark
            case 2: return colors.bgHighlight
            case 3: return colors.bgVisual
            default: return colors.bg
        }
    }

    // Animation durations (snappier, more vim-like)
    readonly property var animation: ({
        instant: 50,
        fast: 100,
        normal: 150,
        slow: 250
    })

    // Easing curves
    readonly property var easing: ({
        standard: Easing.OutCubic,
        decelerate: Easing.OutQuart,
        accelerate: Easing.InQuart
    })

    // Typography - monospace throughout for TUI aesthetic
    readonly property var fonts: ({
        main: "JetBrains Mono",
        title: "JetBrains Mono",
        mono: "JetBrains Mono"
    })

    readonly property var fontSize: ({
        tiny: 10,
        small: 12,
        normal: 13,
        large: 14,
        title: 14,
        headline: 16,
        display: 20
    })

    // Spacing (tighter for TUI aesthetic)
    readonly property var spacing: ({
        tiny: 2,
        small: 4,
        medium: 8,
        large: 12,
        xlarge: 16,
        xxlarge: 24
    })

    // Rounding - minimal to none for TUI aesthetic
    readonly property var rounding: ({
        none: 0,
        tiny: 2,
        small: 3,
        medium: 4,
        large: 6,
        window: 10,  // Match Hyprland window rounding
        full: 9999
    })

    // Border widths
    readonly property var borderWidth: ({
        none: 0,
        thin: 1,
        normal: 1,
        thick: 2
    })

    // Component sizes
    readonly property var sizes: ({
        barHeight: 28,
        sidebarWidth: 400,
        osdWidth: 280,
        osdHeight: 40,
        launcherWidth: 600,
        launcherHeight: 500,
        notificationWidth: 380,
        iconTiny: 12,
        iconSmall: 16,
        iconMedium: 16,
        iconLarge: 20,
        iconXLarge: 24
    })

    // Transparency settings
    property real panelOpacity: 0.92
    property real overlayOpacity: 0.96

    // Lualine-style separator characters
    readonly property var separators: ({
        // Powerline style
        left: "",
        right: "",
        leftThin: "",
        rightThin: "",
        // Simple style
        pipe: "│",
        slashForward: "/",
        slashBack: "\\",
        // Block style
        block: "█",
        blockHalf: "▌"
    })

    // Box drawing characters for TUI borders
    readonly property var box: ({
        topLeft: "┌",
        topRight: "┐",
        bottomLeft: "└",
        bottomRight: "┘",
        horizontal: "─",
        vertical: "│",
        teeLeft: "├",
        teeRight: "┤",
        teeUp: "┴",
        teeDown: "┬",
        cross: "┼",
        // Double line variants
        dTopLeft: "╔",
        dTopRight: "╗",
        dBottomLeft: "╚",
        dBottomRight: "╝",
        dHorizontal: "═",
        dVertical: "║"
    })

    // Helper function to get contrasting text color
    function contrastText(backgroundColor: color): color {
        const r = backgroundColor.r
        const g = backgroundColor.g
        const b = backgroundColor.b
        const luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.5 ? colors.bg : colors.fg
    }

    // Helper for mode-based colors
    function modeColor(mode: string): color {
        switch (mode) {
            case "normal": return colors.modeNormal
            case "insert": return colors.modeInsert
            case "visual": return colors.modeVisual
            case "replace": return colors.modeReplace
            case "command": return colors.modeCommand
            default: return colors.modeNormal
        }
    }

    // Legacy compatibility aliases for m3colors (maps to new colors)
    readonly property var m3colors: ({
        primary: colors.blue,
        onPrimary: colors.bg,
        primaryContainer: colors.bgVisual,
        onPrimaryContainer: colors.fg,
        secondary: colors.green,
        onSecondary: colors.bg,
        secondaryContainer: colors.bgHighlight,
        onSecondaryContainer: colors.fg,
        tertiary: colors.magenta,
        onTertiary: colors.bg,
        tertiaryContainer: colors.bgHighlight,
        onTertiaryContainer: colors.fg,
        error: colors.error,
        onError: colors.bg,
        errorContainer: colors.bgHighlight,
        onErrorContainer: colors.error,
        background: colors.bg,
        onBackground: colors.fg,
        surface: colors.bg,
        onSurface: colors.fg,
        surfaceVariant: colors.bgHighlight,
        onSurfaceVariant: colors.fgDark,
        outline: colors.border,
        outlineVariant: colors.fgGutter,
        inverseSurface: colors.fg,
        inverseOnSurface: colors.bg,
        inversePrimary: colors.bgVisual,
        cyan: colors.cyan,
        orange: colors.orange,
        yellow: colors.yellow,
        magenta: colors.magenta,
        teal: colors.teal,
        comment: colors.comment
    })

    // Helper for backward compatibility - surface layer without tinting
    function surfaceLayer(level: int): color {
        return surfaceColor(level)
    }
}
