pragma Singleton

import QtQuick
import Quickshell

import "providers" as Providers

// Orchestrates search across all providers
Singleton {
    id: root

    // Combined results from all active providers
    property var results: []
    property bool searching: false
    property string currentQuery: ""

    // Current search mode based on query prefix
    property string currentMode: "search"  // search, command, calc, file

    // Signals
    signal resultsReady(var results)
    signal searchStarted(string query)
    signal searchComplete()

    // Search debounce timer to avoid excessive process spawning
    Timer {
        id: debounceTimer
        interval: 50
        repeat: false
        onTriggered: root.executeSearch()
    }

    // Collect results timer
    Timer {
        id: collectTimer
        interval: 150  // Wait for async providers
        repeat: false
        onTriggered: root.collectResults()
    }

    function search(query) {
        console.log("[SearchManager] search called with:", query)
        currentQuery = query

        if (!query || query.trim() === "") {
            results = []
            currentMode = "search"
            searching = false
            resultsReady([])
            return
        }

        // Determine mode based on prefix
        if (query.startsWith("/")) {
            currentMode = "command"
        } else if (query.startsWith("=")) {
            currentMode = "calc"
        } else if (query.startsWith(":")) {
            currentMode = "file"
        } else {
            currentMode = "search"
        }

        searching = true
        searchStarted(query)
        debounceTimer.restart()
    }

    function executeSearch() {
        const query = currentQuery
        console.log("[SearchManager] executeSearch for:", query, "mode:", currentMode)

        // Route to appropriate provider(s) based on prefix
        if (query.startsWith("=")) {
            // Calculator
            console.log("[SearchManager] routing to CalculatorProvider")
            Providers.CalculatorProvider.search(query)
        } else if (query.startsWith("/")) {
            // Command
            console.log("[SearchManager] routing to CommandProvider")
            Providers.CommandProvider.search(query)
        } else if (query.startsWith(":")) {
            // File search
            console.log("[SearchManager] routing to FileProvider")
            Providers.FileProvider.search(query)
        } else {
            // Application search (default)
            console.log("[SearchManager] routing to ApplicationProvider, loaded:", Providers.ApplicationProvider.loaded, "allApps count:", Providers.ApplicationProvider.allApps.length)
            Providers.ApplicationProvider.search(query)
        }

        // Collect results after a delay
        collectTimer.restart()
    }

    function collectResults() {
        console.log("[SearchManager] collectResults called, mode:", currentMode)
        let combinedResults = []

        // Collect from the appropriate provider based on mode
        if (currentMode === "calc") {
            const calcResults = Providers.CalculatorProvider.results
            console.log("[SearchManager] calc results:", calcResults ? calcResults.length : 0)
            if (calcResults && calcResults.length > 0) {
                for (let i = 0; i < calcResults.length; i++) {
                    combinedResults.push(calcResults[i])
                }
            }
        } else if (currentMode === "command") {
            const cmdResults = Providers.CommandProvider.results
            console.log("[SearchManager] command results:", cmdResults ? cmdResults.length : 0)
            if (cmdResults && cmdResults.length > 0) {
                for (let i = 0; i < cmdResults.length; i++) {
                    combinedResults.push(cmdResults[i])
                }
            }
        } else if (currentMode === "file") {
            const fileResults = Providers.FileProvider.results
            console.log("[SearchManager] file results:", fileResults ? fileResults.length : 0)
            if (fileResults && fileResults.length > 0) {
                for (let i = 0; i < fileResults.length; i++) {
                    combinedResults.push(fileResults[i])
                }
            }
        } else {
            // Default: application search
            const appResults = Providers.ApplicationProvider.results
            console.log("[SearchManager] app results:", appResults ? appResults.length : 0)
            if (appResults && appResults.length > 0) {
                for (let i = 0; i < appResults.length; i++) {
                    combinedResults.push(appResults[i])
                }
            }
        }

        console.log("[SearchManager] total combined results:", combinedResults.length)
        results = combinedResults
        searching = false
        resultsReady(combinedResults)
        searchComplete()
    }

    function clear() {
        debounceTimer.stop()
        collectTimer.stop()
        currentQuery = ""
        results = []
        currentMode = "search"
        searching = false

        Providers.ApplicationProvider.clear()
        Providers.CalculatorProvider.clear()
        Providers.CommandProvider.clear()
        Providers.FileProvider.clear()
    }

    // Reload application provider
    function reload() {
        Providers.ApplicationProvider.reload()
    }

    // Check if applications are loaded
    function isReady() {
        return Providers.ApplicationProvider.loaded
    }
}
