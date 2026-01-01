pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Desktop application search provider
Singleton {
    id: root

    // Provider metadata
    readonly property string providerName: "Applications"
    readonly property string prefix: ""  // No prefix required - handles all queries
    readonly property int priority: 10
    property bool enabled: true

    // State
    property bool searching: false
    property bool loaded: false
    property var results: []
    property var allApps: []

    // Configuration
    property int maxResults: 50

    // Pending output buffer
    property string pendingOutput: ""

    // Signals
    signal resultsReady(var results)
    signal appsLoaded()

    // Fixed app loader script using ASCII delimiters to avoid conflicts
    readonly property string appLoaderScript: '
        set -euo pipefail

        # ASCII delimiters that will not appear in desktop files
        SEP=$(printf "\\x1f")  # Unit Separator (ASCII 31)
        REC=$(printf "\\x1e")  # Record Separator (ASCII 30)

        parse_desktop() {
            local file="$1"
            local name="" generic="" icon="" exec_cmd="" comment="" nodisplay="false" categories=""
            local in_desktop_entry=false

            while IFS= read -r line || [[ -n "$line" ]]; do
                # Skip empty lines and comments
                [[ -z "$line" || "$line" == "#"* ]] && continue

                # Track section
                if [[ "$line" == "["*"]" ]]; then
                    [[ "$line" == "[Desktop Entry]" ]] && in_desktop_entry=true || in_desktop_entry=false
                    continue
                fi

                $in_desktop_entry || continue

                # Parse key=value (handle values with = in them)
                local key="${line%%=*}"
                local value="${line#*=}"

                # Skip localized entries (Name[en], etc.)
                [[ "$key" == *"["*"]" ]] && continue

                case "$key" in
                    Name)        [[ -z "$name" ]] && name="$value" ;;
                    GenericName) [[ -z "$generic" ]] && generic="$value" ;;
                    Icon)        icon="$value" ;;
                    Exec)        exec_cmd="$value" ;;
                    Comment)     [[ -z "$comment" ]] && comment="$value" ;;
                    NoDisplay)   nodisplay="$value" ;;
                    Categories)  categories="$value" ;;
                esac
            done < "$file"

            # Skip NoDisplay=true or missing required fields
            [[ "$nodisplay" == "true" ]] && return
            [[ -z "$name" || -z "$exec_cmd" ]] && return

            # Clean exec: remove field codes (%f, %F, %u, %U, etc.)
            exec_cmd=$(echo "$exec_cmd" | sed -E "s/ %[fFuUdDnNickvm]//g")

            # Output record with safe delimiters
            printf "%s${SEP}%s${SEP}%s${SEP}%s${SEP}%s${SEP}%s${REC}" \
                "$name" "$generic" "$icon" "$exec_cmd" "$comment" "$categories"
        }

        # Process system applications
        if [[ -d "/usr/share/applications" ]]; then
            for file in /usr/share/applications/*.desktop; do
                [[ -f "$file" ]] && parse_desktop "$file"
            done
        fi

        # Process user applications (XDG compliant path)
        user_apps="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
        if [[ -d "$user_apps" ]]; then
            for file in "$user_apps"/*.desktop; do
                [[ -f "$file" ]] && parse_desktop "$file"
            done
        fi

        # Process flatpak applications
        flatpak_apps="/var/lib/flatpak/exports/share/applications"
        if [[ -d "$flatpak_apps" ]]; then
            for file in "$flatpak_apps"/*.desktop; do
                [[ -f "$file" ]] && parse_desktop "$file"
            done
        fi

        # Process user flatpak applications
        user_flatpak="${XDG_DATA_HOME:-$HOME/.local/share}/flatpak/exports/share/applications"
        if [[ -d "$user_flatpak" ]]; then
            for file in "$user_flatpak"/*.desktop; do
                [[ -f "$file" ]] && parse_desktop "$file"
            done
        fi
    '

    Process {
        id: appLoader
        command: ["bash", "-c", root.appLoaderScript]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.pendingOutput = this.text
            }
        }

        onRunningChanged: {
            if (running) {
                root.pendingOutput = ""
            }
        }

        onExited: {
            root.searching = false
            root.parseApps(root.pendingOutput)
        }
    }

    function parseApps(output) {
        console.log("[ApplicationProvider] parseApps called, output length:", output ? output.length : 0)
        if (!output) {
            console.log("[ApplicationProvider] no output, marking loaded")
            loaded = true
            appsLoaded()
            return
        }

        const recordSep = String.fromCharCode(30)  // ASCII 30 - Record Separator
        const unitSep = String.fromCharCode(31)    // ASCII 31 - Unit Separator

        const records = output.split(recordSep).filter(r => r.trim() !== "")
        const apps = []
        const seen = new Set()  // Deduplicate by lowercase name

        for (const record of records) {
            const parts = record.split(unitSep)
            if (parts.length < 4) continue

            const name = parts[0]
            const lowerName = name.toLowerCase()

            // Skip duplicates (prefer first occurrence)
            if (seen.has(lowerName)) continue
            seen.add(lowerName)

            apps.push({
                type: "app",
                provider: "ApplicationProvider",
                name: name,
                genericName: parts[1] || "",
                icon: getIconPath(parts[2]),
                exec: parts[3],
                description: parts[4] || parts[1] || "",
                categories: parts[5] ? parts[5].split(";").filter(c => c) : [],
                score: 1.0,
                data: {}
            })
        }

        // Sort alphabetically by name
        apps.sort((a, b) => a.name.localeCompare(b.name))

        console.log("[ApplicationProvider] parsed", apps.length, "apps")
        allApps = apps
        loaded = true
        appsLoaded()
    }

    function getIconPath(iconName) {
        if (!iconName) return ""
        if (iconName.startsWith("/")) return "file://" + iconName
        return "image://icon/" + iconName
    }

    function search(query) {
        console.log("[ApplicationProvider] search called with:", query, "loaded:", loaded, "allApps:", allApps.length)
        if (!loaded) {
            // Apps not loaded yet - queue will be handled by appsLoaded
            console.log("[ApplicationProvider] not loaded yet, returning empty")
            results = []
            resultsReady([])
            return
        }

        if (!query || query.trim() === "") {
            results = []
            resultsReady([])
            return
        }

        const lowerQuery = query.toLowerCase()

        // Score-based fuzzy matching
        const scored = allApps
            .map(app => {
                let score = 0
                const lowerName = app.name.toLowerCase()
                const lowerGeneric = (app.genericName || "").toLowerCase()
                const lowerDesc = (app.description || "").toLowerCase()

                // Exact match at start = highest score
                if (lowerName.startsWith(lowerQuery)) {
                    score = 1.0 - (lowerQuery.length / lowerName.length) * 0.1
                }
                // Name contains query
                else if (lowerName.includes(lowerQuery)) {
                    score = 0.7
                }
                // Generic name match
                else if (lowerGeneric.includes(lowerQuery)) {
                    score = 0.5
                }
                // Description match
                else if (lowerDesc.includes(lowerQuery)) {
                    score = 0.3
                }

                return Object.assign({}, app, { score: score })
            })
            .filter(app => app.score > 0)
            .sort((a, b) => b.score - a.score)
            .slice(0, maxResults)

        console.log("[ApplicationProvider] search found", scored.length, "results")
        results = scored
        resultsReady(scored)
    }

    function clear() {
        results = []
    }

    function canHandle(query) {
        // Applications provider handles all non-prefixed queries
        return query && !query.startsWith("/") && !query.startsWith("=") && !query.startsWith(":")
    }

    function reload() {
        console.log("[ApplicationProvider] reload() called")
        loaded = false
        allApps = []
        searching = true
        appLoader.running = true
    }

    Component.onCompleted: {
        console.log("[ApplicationProvider] Component.onCompleted - starting reload")
        reload()
    }
}
