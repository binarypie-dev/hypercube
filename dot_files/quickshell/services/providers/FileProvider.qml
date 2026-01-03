pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// File and directory search provider
Singleton {
    id: root

    // Provider metadata
    readonly property string providerName: "Files"
    readonly property string prefix: ":"
    readonly property int priority: 20
    property bool enabled: true

    // State
    property bool searching: false
    property var results: []
    property int maxResults: 20

    // Pending output buffer
    property string pendingOutput: ""

    // Signals
    signal resultsReady(var results)
    signal searchError(string error)

    // Current query for the process
    property string currentQuery: ""

    // File search script using find
    readonly property string fileSearchScript: '
        set -euo pipefail
        QUERY="$1"
        MAX="$2"

        SEP=$(printf "\\x1f")
        REC=$(printf "\\x1e")

        # Expand ~ to home directory
        QUERY="${QUERY/#\\~/$HOME}"

        # If exact path exists, show it first
        if [[ -e "$QUERY" ]]; then
            TYPE="file"
            [[ -d "$QUERY" ]] && TYPE="directory"
            NAME=$(basename "$QUERY")
            printf "%s${SEP}%s${SEP}%s${REC}" "$NAME" "$QUERY" "$TYPE"
        fi

        # Determine search directory and pattern
        if [[ -d "$QUERY" ]]; then
            # Query is a directory - list its contents
            DIR="$QUERY"
            PATTERN="*"
        elif [[ "$QUERY" == */* ]]; then
            # Query contains path separator
            DIR=$(dirname "$QUERY" 2>/dev/null || echo "$HOME")
            PATTERN=$(basename "$QUERY" 2>/dev/null || echo "*")
        else
            # Simple name - search from home
            DIR="$HOME"
            PATTERN="$QUERY"
        fi

        # Ensure search directory exists
        [[ -d "$DIR" ]] || DIR="$HOME"

        # Search for matching files (limit depth to avoid slowness)
        find "$DIR" -maxdepth 3 -iname "*${PATTERN}*" -readable 2>/dev/null | head -n "$MAX" | while read -r path; do
            # Skip the exact match we already output
            [[ "$path" == "$QUERY" ]] && continue

            TYPE="file"
            [[ -d "$path" ]] && TYPE="directory"
            NAME=$(basename "$path")
            printf "%s${SEP}%s${SEP}%s${REC}" "$NAME" "$path" "$TYPE"
        done
    '

    Process {
        id: fileSearchProcess
        command: ["bash", "-c", root.fileSearchScript, "--", root.currentQuery, String(root.maxResults)]
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
            root.parseResults(root.pendingOutput)
        }
    }

    function parseResults(output) {
        if (!output) {
            results = []
            resultsReady([])
            return
        }

        const recordSep = String.fromCharCode(30)
        const unitSep = String.fromCharCode(31)

        const records = output.split(recordSep).filter(r => r.trim() !== "")
        const files = []
        const seen = new Set()  // Deduplicate

        for (const record of records) {
            const parts = record.split(unitSep)
            if (parts.length < 3) continue

            const path = parts[1]
            if (seen.has(path)) continue
            seen.add(path)

            const isDir = parts[2] === "directory"
            files.push({
                type: "file",
                provider: "FileProvider",
                name: parts[0],
                icon: isDir ? "image://icon/folder" : "image://icon/text-x-generic",
                description: path,
                exec: "xdg-open \"" + path.replace(/"/g, '\\"') + "\"",
                score: 1.0,
                data: {
                    path: path,
                    isDirectory: isDir
                }
            })
        }

        results = files
        resultsReady(files)
    }

    function search(query) {
        if (!query || !query.startsWith(":")) {
            results = []
            resultsReady([])
            return
        }

        const path = query.substring(1).trim()
        if (!path) {
            results = []
            resultsReady([])
            return
        }

        currentQuery = path
        searching = true
        fileSearchProcess.running = true
    }

    function clear() {
        results = []
        currentQuery = ""
    }

    function canHandle(query) {
        return query && query.startsWith(":")
    }
}
