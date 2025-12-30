pragma Singleton

import QtQuick
import Quickshell

// Shell command execution provider
Singleton {
    id: root

    // Provider metadata
    readonly property string providerName: "Commands"
    readonly property string prefix: "/"
    readonly property int priority: 15
    property bool enabled: true

    // State
    property bool searching: false
    property var results: []

    // Signals
    signal resultsReady(var results)
    signal searchError(string error)

    function search(query) {
        if (!query || !query.startsWith("/")) {
            results = []
            resultsReady([])
            return
        }

        const cmd = query.substring(1).trim()
        if (!cmd) {
            results = []
            resultsReady([])
            return
        }

        results = [{
            type: "command",
            provider: "CommandProvider",
            name: cmd,
            icon: "",
            description: "Run shell command",
            exec: cmd,
            score: 1.0,
            data: {
                command: cmd,
                terminal: false
            }
        }]

        resultsReady(results)
    }

    function clear() {
        results = []
    }

    function canHandle(query) {
        return query && query.startsWith("/")
    }
}
