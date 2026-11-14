import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../common" as Common
import "../../services" as Services

// Thermals view - CPU, GPU, drives, motherboard, fans and platform sensors.
// Readings come from Services.Thermals, which polls fast while this view is
// open. Colors: green ok, yellow warm (>= warn), red hot (>= critical).
Flickable {
    id: root
    contentHeight: contentColumn.height
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Component.onCompleted: Services.Thermals.active = true
    Component.onDestruction: Services.Thermals.active = false

    // Two cards per row when there is room
    readonly property int cardColumns: Math.max(1, Math.floor(width / 380))

    // Only show the scrollbar (and reserve a gutter for it) when the content
    // is taller than the view, so it never overlaps the cards
    readonly property bool needsScroll: contentHeight > height + 1
    readonly property int scrollGutter: needsScroll
        ? scrollBar.width + Common.Appearance.spacing.small
        : 0

    ScrollBar.vertical: ScrollBar {
        id: scrollBar
        policy: ScrollBar.AsNeeded
        visible: root.needsScroll
        width: 6

        contentItem: Rectangle {
            implicitWidth: 4
            radius: 2
            color: Common.Appearance.colors.bgVisual
        }
    }

    ColumnLayout {
        id: contentColumn
        width: root.width - root.scrollGutter
        spacing: Common.Appearance.spacing.medium

        // Header: title and the hottest sensor
        RowLayout {
            Layout.fillWidth: true
            spacing: Common.Appearance.spacing.medium

            Text {
                text: "Thermals"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.large
                font.bold: true
                color: Common.Appearance.colors.fg
            }

            Item { Layout.fillWidth: true }

            Text {
                visible: Services.Thermals.hottest !== null
                Layout.maximumWidth: root.width * 0.6
                elide: Text.ElideRight
                text: {
                    const h = Services.Thermals.hottest
                    if (!h) return ""
                    return "hottest: " + Services.Thermals.sensorName(h.chip, h.sensor)
                        + " " + Math.round(h.sensor.value) + "°C"
                }
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                color: Common.Appearance.colors.fgDark
            }
        }

        // Loading / empty states
        Text {
            visible: !Services.Thermals.ready || Services.Thermals.chips.length === 0
            Layout.fillWidth: true
            text: Services.Thermals.ready ? "No temperature sensors found." : "Reading sensors…"
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.small
            color: Common.Appearance.colors.comment
        }

        // --- CPU & GPU ---------------------------------------------------------
        SectionTitle {
            visible: Services.Thermals.cpuChips.length + Services.Thermals.gpuChips.length > 0
            text: "CPU & GPU"
        }

        GridLayout {
            Layout.fillWidth: true
            visible: Services.Thermals.cpuChips.length + Services.Thermals.gpuChips.length > 0
            columns: root.cardColumns
            columnSpacing: Common.Appearance.spacing.medium
            rowSpacing: Common.Appearance.spacing.medium

            // Indexed models keep delegates alive across polls, so the
            // sparklines don't flicker when the chip list is rebuilt
            Repeater {
                model: Services.Thermals.cpuChips.length
                delegate: ChipCard {
                    required property int index
                    chip: Services.Thermals.cpuChips[index] ?? null
                }
            }

            Repeater {
                model: Services.Thermals.gpuChips.length
                delegate: ChipCard {
                    required property int index
                    chip: Services.Thermals.gpuChips[index] ?? null
                }
            }
        }

        // --- Storage -----------------------------------------------------------
        SectionTitle {
            visible: Services.Thermals.storageChips.length > 0
            text: "Storage"
        }

        GridLayout {
            Layout.fillWidth: true
            visible: Services.Thermals.storageChips.length > 0
            columns: root.cardColumns
            columnSpacing: Common.Appearance.spacing.medium
            rowSpacing: Common.Appearance.spacing.medium

            Repeater {
                model: Services.Thermals.storageChips.length
                delegate: ChipCard {
                    required property int index
                    chip: Services.Thermals.storageChips[index] ?? null
                }
            }
        }

        // --- Motherboard ---------------------------------------------------------
        SectionTitle {
            visible: Services.Thermals.boardChips.length > 0
            text: "Motherboard" + (Services.Thermals.boardName ? "  " + Services.Thermals.boardName : "")
        }

        Card {
            visible: Services.Thermals.boardChips.length > 0

            Repeater {
                model: Services.Thermals.boardChips.length
                delegate: SensorGroup {
                    required property int index
                    chip: Services.Thermals.boardChips[index] ?? null
                    showTitle: Services.Thermals.boardChips.length > 1
                }
            }
        }

        // --- Fans ----------------------------------------------------------------
        SectionTitle {
            visible: Services.Thermals.fans.length > 0 || Services.Thermals.stoppedFans > 0
            text: "Fans"
        }

        Card {
            visible: Services.Thermals.fans.length > 0 || Services.Thermals.stoppedFans > 0

            Flow {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.small

                Repeater {
                    model: Services.Thermals.fans
                    delegate: ReadingChip {
                        required property var modelData
                        label: modelData.label
                        value: modelData.rpm + " rpm"
                        valueColor: Common.Appearance.colors.cyan
                    }
                }
            }

            Text {
                visible: Services.Thermals.stoppedFans > 0
                Layout.fillWidth: true
                text: Services.Thermals.stoppedFans
                    + (Services.Thermals.stoppedFans === 1 ? " fan header" : " fan headers")
                    + " at 0 rpm (stopped or not connected)"
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.tiny
                color: Common.Appearance.colors.comment
            }
        }

        // --- Battery, Wi-Fi, ACPI --------------------------------------------------
        SectionTitle {
            visible: Services.Thermals.platformReadings.length > 0
            text: "Platform"
        }

        Card {
            visible: Services.Thermals.platformReadings.length > 0

            Flow {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.small

                Repeater {
                    model: Services.Thermals.platformReadings
                    delegate: ReadingChip {
                        required property var modelData
                        label: modelData.label
                        value: Math.round(modelData.value) + "°C"
                        valueColor: modelData.rated
                        ? Services.Thermals.levelColor(modelData.level, Common.Appearance.colors)
                        : Common.Appearance.colors.fg
                    }
                }
            }
        }

        Item { Layout.preferredHeight: Common.Appearance.spacing.small }
    }

    // ===========================================================================
    // Components
    // ===========================================================================

    component SectionTitle: Text {
        Layout.fillWidth: true
        elide: Text.ElideRight
        font.family: Common.Appearance.fonts.mono
        font.pixelSize: Common.Appearance.fontSize.small
        font.bold: true
        color: Common.Appearance.colors.fgDark
    }

    // Bordered card; children stack in a column
    component Card: Rectangle {
        default property alias content: cardColumn.data

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        Layout.preferredHeight: cardColumn.implicitHeight + Common.Appearance.spacing.medium * 2
        color: Common.Appearance.colors.bgDark
        border.width: 1
        border.color: Common.Appearance.colors.border
        radius: Common.Appearance.rounding.tiny

        ColumnLayout {
            id: cardColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Common.Appearance.spacing.medium
            spacing: Common.Appearance.spacing.small
        }
    }

    // Small "label value" chip
    component ReadingChip: Rectangle {
        id: readingChip
        property string label: ""
        property string value: ""
        property color valueColor: Common.Appearance.colors.fg

        implicitWidth: chipRow.implicitWidth + Common.Appearance.spacing.medium * 2
        implicitHeight: 20
        radius: Common.Appearance.rounding.tiny
        color: Common.Appearance.colors.bgHighlight

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: Common.Appearance.spacing.small

            Text {
                text: readingChip.label
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.tiny
                color: Common.Appearance.colors.fgDark
            }

            Text {
                text: readingChip.value
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.tiny
                font.bold: true
                color: readingChip.valueColor
            }
        }
    }

    // A chip's temperatures as a row of reading chips, optionally titled
    component SensorGroup: ColumnLayout {
        id: group
        property var chip: null
        property bool showTitle: true

        Layout.fillWidth: true
        spacing: Common.Appearance.spacing.tiny

        Text {
            visible: group.showTitle && group.chip !== null
            text: group.chip ? group.chip.title : ""
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.tiny
            color: Common.Appearance.colors.comment
        }

        Flow {
            Layout.fillWidth: true
            spacing: Common.Appearance.spacing.small

            Repeater {
                model: group.chip ? group.chip.temps : []
                delegate: ReadingChip {
                    required property var modelData
                    label: modelData.label
                    value: Math.round(modelData.value) + "°C"
                    valueColor: modelData.rated
                        ? Services.Thermals.levelColor(modelData.level, Common.Appearance.colors)
                        : Common.Appearance.colors.fg
                }
            }
        }
    }

    // CPU, GPU or drive: title, main reading with bar and sparkline, then the
    // rest of its sensors and stats
    component ChipCard: Card {
        id: card
        property var chip: null
        readonly property var primary: chip ? chip.primary : null
        readonly property color primaryColor: primary
            ? Services.Thermals.levelColor(primary.level, Common.Appearance.colors)
            : Common.Appearance.colors.comment

        // Title row
        RowLayout {
            Layout.fillWidth: true
            spacing: Common.Appearance.spacing.small

            Text {
                Layout.fillWidth: true
                text: card.chip ? card.chip.title : ""
                elide: Text.ElideRight
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.small
                font.bold: true
                color: Common.Appearance.colors.fg
            }

            // The drive the system runs from
            Rectangle {
                visible: card.chip !== null && card.chip.isRoot
                implicitWidth: rootTag.implicitWidth + Common.Appearance.spacing.medium * 2
                implicitHeight: 16
                radius: Common.Appearance.rounding.tiny
                color: "transparent"
                border.width: 1
                border.color: Common.Appearance.colors.cyan

                Text {
                    id: rootTag
                    anchors.centerIn: parent
                    text: "system"
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.tiny
                    color: Common.Appearance.colors.cyan
                }
            }
        }

        Text {
            visible: card.chip !== null && card.chip.asleep
            text: "Asleep: not polled, so it can stay powered down"
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.tiny
            color: Common.Appearance.colors.comment
        }

        // Main reading: value, bar against the critical limit, sparkline
        RowLayout {
            visible: card.primary !== null
            Layout.fillWidth: true
            spacing: Common.Appearance.spacing.medium

            Text {
                Layout.preferredWidth: 64
                text: card.primary ? Math.round(card.primary.value) + "°C" : ""
                font.family: Common.Appearance.fonts.mono
                font.pixelSize: Common.Appearance.fontSize.display
                font.bold: true
                color: card.primaryColor
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Common.Appearance.spacing.tiny

                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: card.primary
                        ? card.primary.label + "  warn " + Math.round(card.primary.warn)
                            + "°  crit " + Math.round(card.primary.crit) + "°"
                        : ""
                    font.family: Common.Appearance.fonts.mono
                    font.pixelSize: Common.Appearance.fontSize.tiny
                    color: Common.Appearance.colors.comment
                }

                // Bar: how far the reading is toward its critical limit
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    color: "transparent"
                    border.width: 1
                    border.color: Common.Appearance.colors.border
                    radius: Common.Appearance.rounding.tiny

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 2
                        width: card.primary
                            ? Math.max(0, Math.min(1, card.primary.value / card.primary.crit)) * (parent.width - 4)
                            : 0
                        radius: Common.Appearance.rounding.tiny
                        color: card.primaryColor
                    }

                    // Warn marker
                    Rectangle {
                        visible: card.primary !== null
                        x: card.primary ? card.primary.warn / card.primary.crit * (parent.width - 4) + 2 : 0
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        color: Common.Appearance.colors.yellow
                        opacity: 0.6
                    }
                }
            }

            Common.Sparkline {
                Layout.preferredWidth: 120
                Layout.preferredHeight: 30
                points: card.primary ? (Services.Thermals.history[card.primary.uid] || []) : []
                windowMs: Services.Thermals.historyMs
                ceiling: card.primary ? card.primary.crit : 100
                color: card.primaryColor
            }
        }

        // GPU load, fan and power
        Text {
            readonly property var parts: {
                const c = card.chip
                if (!c || c.asleep) return []
                const p = []
                if (c.stats.load !== undefined) p.push("load " + c.stats.load + "%")
                if (c.stats.fan !== undefined) p.push("fan " + c.stats.fan + "%")
                for (const f of c.fans) if (f.rpm > 0) p.push(f.label.toLowerCase() + " " + f.rpm + " rpm")
                if (c.stats.power !== undefined) p.push(c.stats.power + " W")
                return p
            }
            visible: parts.length > 0
            Layout.fillWidth: true
            text: parts.join("  ·  ")
            elide: Text.ElideRight
            font.family: Common.Appearance.fonts.mono
            font.pixelSize: Common.Appearance.fontSize.tiny
            color: Common.Appearance.colors.fgDark
        }

        // Other sensors (CCDs, cores, hotspot, drive sensors)
        Flow {
            readonly property var others: card.chip
                ? card.chip.temps.filter(t => !card.primary || t.uid !== card.primary.uid)
                : []
            visible: others.length > 0
            Layout.fillWidth: true
            spacing: Common.Appearance.spacing.small

            Repeater {
                model: parent.others
                delegate: ReadingChip {
                    required property var modelData
                    label: modelData.label
                    value: Math.round(modelData.value) + "°C"
                    valueColor: modelData.rated
                        ? Services.Thermals.levelColor(modelData.level, Common.Appearance.colors)
                        : Common.Appearance.colors.fg
                }
            }
        }
    }
}
