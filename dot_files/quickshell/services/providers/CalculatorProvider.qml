pragma Singleton

import QtQuick
import Quickshell

// Calculator/math expression provider
Singleton {
    id: root

    // Provider metadata
    readonly property string providerName: "Calculator"
    readonly property string prefix: "="
    readonly property int priority: 5  // Highest priority when triggered
    property bool enabled: true

    // State
    property bool searching: false
    property var results: []

    // Signals
    signal resultsReady(var results)
    signal searchError(string error)

    function search(query) {
        if (!query || !query.startsWith("=")) {
            results = []
            resultsReady([])
            return
        }

        const expr = query.substring(1).trim()
        if (!expr) {
            results = []
            resultsReady([])
            return
        }

        try {
            // Sanitize: only allow safe math characters and functions
            // Allow: digits, operators, parentheses, decimal, common math functions
            const sanitized = expr.replace(/\s+/g, "")

            // Check for invalid characters (basic safety check)
            if (!/^[\d\s\+\-\*\/\(\)\.\,\^%a-zA-Z]+$/.test(sanitized)) {
                throw new Error("Invalid characters in expression")
            }

            // Replace common math notation
            let jsExpr = sanitized
                .replace(/\^/g, "**")           // Exponentiation
                .replace(/(\d)([a-zA-Z])/g, "$1*$2")  // Implicit multiplication (2pi -> 2*pi)

            // Replace math constants
            jsExpr = jsExpr
                .replace(/\bpi\b/gi, "Math.PI")
                .replace(/\be\b/g, "Math.E")

            // Replace math functions
            jsExpr = jsExpr
                .replace(/\bsqrt\(/gi, "Math.sqrt(")
                .replace(/\babs\(/gi, "Math.abs(")
                .replace(/\bsin\(/gi, "Math.sin(")
                .replace(/\bcos\(/gi, "Math.cos(")
                .replace(/\btan\(/gi, "Math.tan(")
                .replace(/\blog\(/gi, "Math.log10(")
                .replace(/\bln\(/gi, "Math.log(")
                .replace(/\bexp\(/gi, "Math.exp(")
                .replace(/\bpow\(/gi, "Math.pow(")
                .replace(/\bfloor\(/gi, "Math.floor(")
                .replace(/\bceil\(/gi, "Math.ceil(")
                .replace(/\bround\(/gi, "Math.round(")

            // Safe evaluation using Function constructor
            const result = Function('"use strict"; return (' + jsExpr + ')')()

            if (typeof result === "number" && !isNaN(result) && isFinite(result)) {
                // Format result nicely
                let formattedResult
                if (Number.isInteger(result)) {
                    formattedResult = result.toString()
                } else {
                    // Remove trailing zeros but keep precision
                    formattedResult = result.toPrecision(12).replace(/\.?0+$/, "")
                }

                results = [{
                    type: "calc",
                    provider: "CalculatorProvider",
                    name: formattedResult,
                    icon: "",
                    description: expr + " = " + formattedResult,
                    exec: "",  // Will copy to clipboard on select
                    score: 1.0,
                    data: {
                        expression: expr,
                        result: result
                    }
                }]
            } else {
                results = [{
                    type: "calc",
                    provider: "CalculatorProvider",
                    name: "Invalid result",
                    icon: "",
                    description: "Expression did not evaluate to a valid number",
                    exec: "",
                    score: 0,
                    data: { error: true }
                }]
            }
        } catch (e) {
            results = [{
                type: "calc",
                provider: "CalculatorProvider",
                name: "Error",
                icon: "",
                description: e.message || "Invalid expression",
                exec: "",
                score: 0,
                data: { error: true, message: e.message }
            }]
        }

        resultsReady(results)
    }

    function clear() {
        results = []
    }

    function canHandle(query) {
        return query && query.startsWith("=")
    }
}
