pragma Singleton

import QtQuick
import Quickshell

import "../modules/common" as Common

Singleton {
    id: root

    property string timeString: "00:00"
    property string dateString: ""
    property string fullDateTime: ""
    property string fullDateTimeString: ""  // Human-readable format for tooltips

    property int hour: 0
    property int minute: 0
    property int second: 0
    property int day: 1
    property int month: 1
    property int year: 2024
    property int dayOfWeek: 0

    readonly property var dayNames: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    function update() {
        const now = new Date()

        hour = now.getHours()
        minute = now.getMinutes()
        second = now.getSeconds()
        day = now.getDate()
        month = now.getMonth() + 1
        year = now.getFullYear()
        dayOfWeek = now.getDay()

        // Format time string based on 12/24 hour preference
        if (Common.Config.use24Hour) {
            timeString = pad(hour) + ":" + pad(minute)
        } else {
            const hour12 = hour % 12 || 12
            const ampm = hour < 12 ? "AM" : "PM"
            timeString = pad(hour12) + ":" + pad(minute) + " " + ampm
        }

        // Format date string: YYYY.MM.DD
        dateString = year + "." + pad(month) + "." + pad(day)

        // Full date time
        fullDateTime = dateString + " " + timeString

        // Human-readable full date time for tooltips: "Wednesday, January 1, 2026  12:45 PM"
        fullDateTimeString = dayNames[dayOfWeek] + ", " + monthNames[month - 1] + " " + day + ", " + year + "  " + timeString
    }

    function pad(num: int): string {
        return num < 10 ? "0" + num : "" + num
    }

    // Check if it's night time (for weather icons, etc.)
    function isNight(): bool {
        return hour < 6 || hour >= 20
    }

    // Get relative time string
    function relativeTime(timestamp: var): string {
        const now = new Date()
        const then = new Date(timestamp)
        const diff = Math.floor((now - then) / 1000) // seconds

        if (diff < 60) return "Just now"
        if (diff < 3600) return Math.floor(diff / 60) + "m ago"
        if (diff < 86400) return Math.floor(diff / 3600) + "h ago"
        if (diff < 604800) return Math.floor(diff / 86400) + "d ago"
        return then.toLocaleDateString()
    }

    Component.onCompleted: update()
}
