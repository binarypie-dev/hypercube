pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Centralized service for datacube-cli interactions
// Handles JSON parsing and provides a consistent API for all components
Singleton {
    id: root

    // Signals for async query results
    signal queryCompleted(string queryId, var results)
    signal queryFailed(string queryId, string error)

    // Track active queries
    property var activeQueries: ({})

    // Query datacube with optional filters
    // Returns a queryId that will be emitted with results
    function query(searchText, options) {
        const queryId = generateQueryId()
        const opts = options || {}

        const args = ["datacube-cli", "query", searchText || "", "--json"]

        if (opts.maxResults) {
            args.push("-m", opts.maxResults.toString())
        }
        if (opts.provider) {
            args.push("-p", opts.provider)
        }

        const proc = queryComponent.createObject(root, {
            queryId: queryId,
            command: args
        })

        activeQueries[queryId] = proc
        proc.running = true

        return queryId
    }

    // Convenience method: query applications
    function queryApplications(searchText, maxResults) {
        return query(searchText, {
            provider: "applications",
            maxResults: maxResults || 500
        })
    }

    // Convenience method: query all providers
    function queryAll(searchText, maxResults) {
        return query(searchText, {
            maxResults: maxResults || 50
        })
    }

    // Cancel an active query
    function cancelQuery(queryId) {
        if (activeQueries[queryId]) {
            activeQueries[queryId].running = false
            activeQueries[queryId].destroy()
            delete activeQueries[queryId]
        }
    }

    // Parse a datacube result item into our standard format
    function parseResult(item) {
        return {
            id: item.id || "",
            type: item.provider === "applications" ? "app" : item.provider,
            name: item.text || "",
            description: item.subtext || "",
            genericName: item.subtext || "",
            icon: formatIconPath(item.icon_path || item.icon || ""),
            exec: item.exec || "",
            provider: item.provider || "",
            score: item.score || 0,
            metadata: item.metadata || {},
            _raw: item
        }
    }

    // Format icon path for QML Image source
    function formatIconPath(iconPath) {
        if (!iconPath) return ""
        if (iconPath.startsWith("/")) return "file://" + iconPath
        if (iconPath.startsWith("file://")) return iconPath
        // Fallback to icon theme lookup
        return "image://icon/" + iconPath
    }

    // Generate unique query ID
    function generateQueryId() {
        return "q_" + Date.now() + "_" + Math.random().toString(36).substr(2, 9)
    }

    // Query process component
    Component {
        id: queryComponent

        Process {
            id: proc
            property string queryId: ""
            property string outputBuffer: ""

            stdout: StdioCollector {
                onStreamFinished: {
                    proc.outputBuffer = this.text
                }
            }

            onStarted: {
                proc.outputBuffer = ""
            }

            onExited: (exitCode, exitStatus) => {
                // Remove from active queries
                delete root.activeQueries[proc.queryId]

                if (exitCode !== 0) {
                    root.queryFailed(proc.queryId, "Process exited with code " + exitCode)
                    proc.destroy()
                    return
                }

                try {
                    const items = JSON.parse(proc.outputBuffer)
                    const results = items.map(item => root.parseResult(item))
                    root.queryCompleted(proc.queryId, results)
                } catch (e) {
                    root.queryFailed(proc.queryId, "JSON parse error: " + e)
                }

                proc.destroy()
            }
        }
    }
}
