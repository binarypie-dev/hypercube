pragma Singleton

import QtQuick
import Quickshell

// Icon resolution service using Datacube for icon lookups
// Maintains a cache of resolved icon paths for window classes, app names, etc.
Singleton {
    id: root

    // Icon cache: maps query string to resolved icon path
    property var iconCache: ({})
    // Track which queries are in progress
    property var pendingQueries: ({})  // queryId -> cacheKey mapping

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
        const alreadyPending = Object.values(pendingQueries).includes(cacheKey)
        if (!alreadyPending) {
            lookupIcon(query, cacheKey)
        }

        // Return empty - will update when cache populates
        return ""
    }

    // Force a lookup even if already cached (for refresh scenarios)
    function refreshIcon(query) {
        if (!query) return
        const cacheKey = query.toLowerCase()
        lookupIcon(query, cacheKey)
    }

    // Check if an icon is cached
    function hasIcon(query) {
        if (!query) return false
        return !!iconCache[query.toLowerCase()]
    }

    // Internal: perform the datacube lookup
    function lookupIcon(query, cacheKey) {
        if (!query) return

        const queryId = Datacube.queryApplications(query, 1)
        pendingQueries[queryId] = cacheKey
    }

    // Handle Datacube query results
    Connections {
        target: Datacube

        function onQueryCompleted(queryId, results) {
            const cacheKey = root.pendingQueries[queryId]
            if (!cacheKey) return

            delete root.pendingQueries[queryId]

            if (results.length > 0 && results[0].icon) {
                // Update the cache - create new object to trigger binding updates
                let newCache = Object.assign({}, root.iconCache)
                newCache[cacheKey] = results[0].icon
                root.iconCache = newCache
            }
        }

        function onQueryFailed(queryId, error) {
            const cacheKey = root.pendingQueries[queryId]
            if (cacheKey) {
                delete root.pendingQueries[queryId]
                console.log("IconResolver: lookup failed for", cacheKey, "-", error)
            }
        }
    }
}
