pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Icon resolution service using datacube for flatpak and other icon lookups
Singleton {
    id: root

    // Icon cache: maps query string to resolved icon path
    property var iconCache: ({})
    // Track which queries are in progress
    property var queriesInProgress: ({})

    // Get icon for a given query (app name, window class, etc.)
    // Returns cached path if available, empty string if not yet resolved
    function getIcon(query) {
        if (!query) return ""

        const cacheKey = query.toLowerCase()

        // Return from cache if available
        if (iconCache[cacheKey]) {
            return iconCache[cacheKey]
        }

        // Trigger a lookup if not already in progress
        if (!queriesInProgress[cacheKey]) {
            lookupIcon(query, cacheKey)
        }

        // Return empty - will update when cache populates
        return ""
    }

    // Force a lookup even if already cached (for refresh scenarios)
    function refreshIcon(query) {
        if (!query) return
        const cacheKey = query.toLowerCase()
        if (!queriesInProgress[cacheKey]) {
            lookupIcon(query, cacheKey)
        }
    }

    // Check if an icon is cached
    function hasIcon(query) {
        if (!query) return false
        return !!iconCache[query.toLowerCase()]
    }

    // Internal: perform the datacube lookup
    function lookupIcon(query, cacheKey) {
        if (!query) return

        queriesInProgress[cacheKey] = true

        const proc = iconLookupComponent.createObject(root, {
            query: query,
            cacheKey: cacheKey
        })
        proc.running = true
    }

    Component {
        id: iconLookupComponent

        Process {
            id: iconProc
            property string query: ""
            property string cacheKey: ""
            command: ["bash", "-lc", "datacube-cli query '" + query.replace(/'/g, "'\\''") + "' --json -m 1 -p applications"]

            stdout: SplitParser {
                splitMarker: "\n"
                onRead: data => {
                    if (!data || data.trim() === "") return
                    try {
                        const item = JSON.parse(data)
                        if (item.icon) {
                            let iconPath
                            if (item.icon.startsWith("/")) {
                                iconPath = "file://" + item.icon
                            } else {
                                iconPath = "image://icon/" + item.icon
                            }
                            // Update the cache - create new object to trigger binding updates
                            let newCache = Object.assign({}, root.iconCache)
                            newCache[iconProc.cacheKey] = iconPath
                            root.iconCache = newCache
                        }
                    } catch (e) {
                        console.log("IconResolver: Failed to parse lookup result:", e)
                    }
                }
            }

            onExited: {
                // Remove from in-progress tracking
                let newInProgress = Object.assign({}, root.queriesInProgress)
                delete newInProgress[iconProc.cacheKey]
                root.queriesInProgress = newInProgress

                // Clean up this process object
                iconProc.destroy()
            }
        }
    }
}
