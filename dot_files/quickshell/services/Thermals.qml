pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Hardware temperatures for the hub's Thermals tab.
//
// Sensors come from scripts/thermals.sh (hwmon in sysfs, plus nvidia-smi for
// the NVIDIA driver). While the tab is open it polls every 2s; otherwise it
// keeps a slow background watch and sends a desktop notification when any
// sensor crosses its critical limit (e.g. an NVMe drive running without its
// heatsink).
//
// Every sensor gets a level: 0 ok, 1 warm (>= warn), 2 hot (>= crit). Limits
// come from the hardware when it reports sane ones (NVMe drives, AMD GPUs,
// Intel CPUs, NVIDIA slowdown temps); otherwise per-category defaults.
Singleton {
    id: root

    // Set by ThermalsView while it is on screen: poll fast
    property bool active: false
    readonly property int activeInterval: 2000
    readonly property int idleInterval: 30000

    // Sparkline window for the key sensors
    readonly property int historyMs: 5 * 60 * 1000

    // Facts from `thermals.sh init`
    property string cpuModel: ""
    property string boardName: ""
    property string rootDevice: ""  // nvme controller (nvme0) or disk (sda)
    property var gpuLimits: ({})    // "nvidia0" -> { target, max, crit } (°C)

    // Live readings, rebuilt on every poll. Each chip:
    //   { id, category, name, title, device, isRoot, asleep, stats,
    //     temps: [sensor], primary: sensor, fans: [{ label, rpm }] }
    // Each sensor: { uid, key, label, value, warn, crit, level, rated }
    // A sensor is unrated when it reports no limits but a sibling does (NVMe
    // "Sensor 1/2": the drive only rates its Composite reading). Unrated
    // sensors are shown without a level and never raise an alert.
    property var chips: []
    property var fans: []        // non-GPU fans that are spinning: [{ label, rpm, chip }]
    property int stoppedFans: 0  // fan headers reading 0 RPM (stopped or not connected)
    property var hottest: null   // { chip, sensor } with the highest level, then temperature
    property int level: 0        // worst sensor level
    readonly property bool alert: level >= 2
    property bool ready: false
    property var history: ({})   // sensor uid -> [{ t, v }] for primary sensors

    readonly property var cpuChips: chips.filter(c => c.category === "cpu")
    readonly property var gpuChips: chips.filter(c => c.category === "gpu")
    readonly property var storageChips: chips.filter(c => c.category === "storage")
    readonly property var boardChips: chips.filter(c => c.category === "board")
    readonly property var platformChips: chips.filter(c => c.category === "platform")
    // Platform sensors flattened; single-sensor chips are named after the chip
    readonly property var platformReadings: {
        const out = []
        for (const c of platformChips) {
            for (const t of c.temps) {
                out.push({
                    uid: t.uid, value: t.value, level: t.level, rated: t.rated,
                    label: c.temps.length === 1 ? c.title : c.title + " " + t.label
                })
            }
        }
        return out
    }

    // Fallback limits (°C) when a sensor doesn't report usable ones
    readonly property var defaults: ({
        cpu: { warn: 85, crit: 95 },
        gpu: { warn: 83, crit: 90 },
        storage: { warn: 70, crit: 80 },
        board: { warn: 75, crit: 90 },
        platform: { warn: 70, crit: 90 },
        battery: { warn: 45, crit: 55 }
    })

    // Sensors already notified about; cleared once they drop below warn
    property var notified: ({})

    readonly property string scriptPath: decodeURIComponent(
        Qt.resolvedUrl("../scripts/thermals.sh").toString().replace(/^file:\/\//, ""))

    // Called from shell.qml so the background watch runs from login, not
    // only once the hub is first opened
    function start() {
        if (!initProcess.running && root.cpuModel === "" && root.boardName === "")
            initProcess.running = true
    }

    function poll() {
        if (!pollProcess.running) pollProcess.running = true
    }

    onActiveChanged: {
        if (active) {
            poll()
            pollTimer.restart()
        }
    }

    function levelColor(lvl: int, colors: var): color {
        if (lvl >= 2) return colors.red
        if (lvl >= 1) return colors.yellow
        return colors.green
    }

    function levelName(lvl: int): string {
        return lvl >= 2 ? "HOT" : (lvl >= 1 ? "WARM" : "OK")
    }

    // --- Naming ---------------------------------------------------------------

    function chipTitle(name: string, title: string, category: string): string {
        if (category === "cpu") return root.cpuModel || "CPU"
        if (name === "asus_ec_sensors" || name === "asus-ec-sensors") return "ASUS EC"
        if (/^(nct|it8|f71|w83)/.test(name)) return "Super I/O (" + name + ")"
        if (name === "acpitz") return "ACPI thermal zone"
        if (/^BAT/.test(name)) return "Battery"
        if (/^(iwlwifi|mt7|ath|rtw|brcm)/.test(name)) return "Wi-Fi"
        if (/^r8169/.test(name)) return "Ethernet"
        if (name === "spd5118" || name === "jc42") return "Memory"
        if (/^pch_/.test(name)) return "Chipset (PCH)"
        if (name === "nouveau") return "NVIDIA GPU (nouveau)"
        if (name === "i915" || name === "xe") return "Intel GPU"
        return title || name
    }

    function sensorLabel(name: string, label: string, key: string, count: int): string {
        if (label === "Tctl") return "Package"
        if (label === "Tdie") return "Die"
        let m = /^Tccd(\d+)$/.exec(label)
        if (m) return "CCD " + m[1]
        if (/^Package id \d+$/.test(label)) return "Package"
        if (name === "amdgpu") {
            if (label === "edge") return "Edge"
            if (label === "junction") return "Hotspot"
            if (label === "mem") return "Memory"
        }
        if (label) return label.replace(/_/g, " ")
        if (count === 1) return "Temperature"
        m = /^temp(\d+)$/.exec(key)
        return "Sensor " + (m ? m[1] : key)
    }

    // "FireCuda 520 (nvme0)" for a chip's main reading, else "<chip> <sensor>"
    function sensorName(chip: var, sensor: var): string {
        if (chip.temps.length <= 1 || (chip.primary && chip.primary.uid === sensor.uid)) return chip.title
        return chip.title + " " + sensor.label
    }

    // The reading that represents the chip in summaries and sparklines
    function pickPrimary(chip: var): var {
        const t = chip.temps.filter(x => x.rated)
        if (t.length === 0) return null
        const prefer = ["Package", "Die", "Composite", "Edge", "GPU"]
        for (const p of prefer) {
            const s = t.find(x => x.label === p)
            if (s) return s
        }
        if (chip.category === "storage" || chip.category === "gpu") return t[0]
        return t.reduce((a, b) => b.value > a.value ? b : a)
    }

    // --- Limits ---------------------------------------------------------------

    // Reported limits outside this range are firmware placeholders
    function sane(v: real): bool {
        return !isNaN(v) && v >= 40 && v <= 150
    }

    function applyLimits(chip: var, raw: var) {
        const d = /^BAT/.test(chip.name)
            ? root.defaults.battery
            : (root.defaults[chip.category] || root.defaults.board)
        const gl = root.gpuLimits[chip.id]

        const hasRatedSibling = raw.some(r => root.sane(r.crit) || root.sane(r.max))

        for (let i = 0; i < chip.temps.length; i++) {
            const s = chip.temps[i]
            let max = raw[i].max
            let crit = raw[i].crit
            s.rated = !!gl || root.sane(max) || root.sane(crit) || !hasRatedSibling
            if (!s.rated) {
                s.level = 0
                continue
            }

            let c, w
            if (gl) {
                c = gl.crit || d.crit
                w = gl.target || gl.max || (c - 5)
            } else {
                c = root.sane(crit) ? crit : (root.sane(max) ? Math.max(max + 5, d.crit) : d.crit)
                w = root.sane(max) && max < c ? max : Math.min(d.warn, c - 5)
            }
            s.crit = c
            s.warn = Math.min(w, c - 1)
            s.level = s.value >= s.crit ? 2 : (s.value >= s.warn ? 1 : 0)
        }
    }

    // --- Parsing --------------------------------------------------------------

    function num(v: string): real {
        if (v === undefined || v === "" || v === "-") return NaN
        const n = parseFloat(v)
        return isNaN(n) ? NaN : n / 1000
    }

    function parseInit(text: string) {
        const limits = {}
        for (const line of text.split("\n")) {
            const f = line.split("\t")
            switch (f[0]) {
                case "cpu":
                    root.cpuModel = (f[1] || "")
                        .replace(/\((R|TM)\)/gi, "")
                        .replace(/ (CPU|Processor)\b/g, "")
                        .replace(/\s+/g, " ").trim()
                    break
                case "board":
                    root.boardName = (f[1] || "")
                        .replace(/^ASUSTeK COMPUTER INC\.?/i, "ASUS")
                        .replace(/^Micro-Star International Co\., Ltd\.?/i, "MSI")
                        .replace(/^Gigabyte Technology Co\., Ltd\.?/i, "Gigabyte")
                        .replace(/^Dell Inc\.?/i, "Dell")
                        .replace(/^LENOVO/, "Lenovo")
                        .replace(/\s+/g, " ").trim()
                    break
                case "root": root.rootDevice = (f[1] || "").trim(); break
                case "limit": {
                    if (!limits[f[1]]) limits[f[1]] = {}
                    const v = root.num(f[3])
                    if (!isNaN(v)) limits[f[1]][f[2]] = v
                    break
                }
            }
        }
        root.gpuLimits = limits
        root.poll()
    }

    function parsePoll(text: string) {
        const byId = {}
        const order = []
        const raw = {}
        const fans = []
        let stopped = 0

        for (const line of text.split("\n")) {
            if (!line) continue
            const f = line.split("\t")
            const kind = f[0]
            const id = f[1]

            if (kind === "chip") {
                if (!byId[id]) {
                    byId[id] = {
                        id: id, category: f[2], name: f[3],
                        title: root.chipTitle(f[3], f[4], f[2]),
                        device: "", isRoot: false, asleep: false,
                        stats: {}, temps: [], fans: [], primary: null
                    }
                    raw[id] = []
                    order.push(id)
                }
                continue
            }

            const chip = byId[id]
            if (!chip) continue

            if (kind === "temp") {
                const value = root.num(f[4])
                // Unconnected sensor inputs read as nonsense (-62, 127, 0)
                if (isNaN(value) || value <= 0 || value >= 125) continue
                chip.temps.push({
                    uid: id + ":" + f[2], key: f[2], label: f[3],
                    value: value, warn: 0, crit: 0, level: 0, rated: true
                })
                raw[id].push({ max: root.num(f[5]), crit: root.num(f[6]) })
            } else if (kind === "fan") {
                const rpm = parseInt(f[3])
                if (isNaN(rpm) || rpm < 0 || rpm > 20000) continue
                const label = (f[2] || "").replace(/_/g, " ")
                if (chip.category === "gpu") {
                    chip.fans.push({ label: label, rpm: rpm })
                } else if (rpm === 0) {
                    stopped++
                } else {
                    fans.push({ label: label, rpm: rpm, chip: id })
                }
            } else if (kind === "stat") {
                if (f[2] === "device") chip.device = f[3]
                else if (f[2] === "asleep") chip.asleep = f[3] === "1"
                else chip.stats[f[2]] = parseInt(f[3])
            }
        }

        const chips = []
        let worst = 0
        let hottest = null
        const now = Date.now()
        const history = {}
        const notified = Object.assign({}, root.notified)

        for (const id of order) {
            const chip = byId[id]
            // Chips with nothing to show (e.g. ucsi power supplies)
            if (chip.temps.length === 0 && chip.fans.length === 0 && !chip.asleep) continue

            const count = chip.temps.length
            for (const s of chip.temps) s.label = root.sensorLabel(chip.name, s.label, s.key, count)
            root.applyLimits(chip, raw[id])
            chip.primary = root.pickPrimary(chip)
            chip.isRoot = chip.device !== "" && chip.device === root.rootDevice

            for (const s of chip.temps) {
                if (!s.rated) continue
                worst = Math.max(worst, s.level)
                if (!hottest || s.level > hottest.sensor.level
                        || (s.level === hottest.sensor.level && s.value > hottest.sensor.value)) {
                    hottest = { chip: chip, sensor: s }
                }

                if (s.level >= 2 && !notified[s.uid]) {
                    notified[s.uid] = true
                    root.notify(chip, s)
                } else if (s.value < s.warn && notified[s.uid]) {
                    delete notified[s.uid]
                }
            }

            // History for the sensors that get a sparkline
            const p = chip.primary
            if (p && (chip.category === "cpu" || chip.category === "gpu" || chip.category === "storage")) {
                const prev = root.history[p.uid] || []
                const kept = prev.filter(h => now - h.t <= root.historyMs)
                kept.push({ t: now, v: p.value })
                history[p.uid] = kept
            }

            chips.push(chip)
        }

        fans.sort((a, b) => a.label.localeCompare(b.label, undefined, { numeric: true }))

        root.notified = notified
        root.history = history
        root.fans = fans
        root.stoppedFans = stopped
        root.hottest = hottest
        root.level = worst
        root.chips = chips
        root.ready = true
    }

    // --- Notifications --------------------------------------------------------

    function notify(chip: var, sensor: var) {
        const what = root.sensorName(chip, sensor)
        notifyProcess.command = [
            "gdbus", "call", "--session",
            "--dest", "org.freedesktop.Notifications",
            "--object-path", "/org/freedesktop/Notifications",
            "--method", "org.freedesktop.Notifications.Notify",
            "Thermals", "0", "dialog-warning",
            what + " is overheating",
            Math.round(sensor.value) + "°C, critical limit " + Math.round(sensor.crit)
                + "°C. Check its cooling.",
            "[]", "{'urgency': <byte 2>}", "0"
        ]
        notifyProcess.startDetached()
    }

    // --- Processes --------------------------------------------------------------

    Process {
        id: initProcess
        command: ["bash", root.scriptPath, "init"]
        stdout: StdioCollector {
            id: initOut
            onStreamFinished: root.parseInit(initOut.text)
        }
    }

    Process {
        id: pollProcess
        command: ["bash", root.scriptPath]
        stdout: StdioCollector {
            id: pollOut
            onStreamFinished: root.parsePoll(pollOut.text)
        }
    }

    Process {
        id: notifyProcess
    }

    Timer {
        id: pollTimer
        interval: root.active ? root.activeInterval : root.idleInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }
}
