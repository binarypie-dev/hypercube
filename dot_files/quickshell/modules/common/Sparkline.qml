import QtQuick

// Small line graph of recent values, e.g. a temperature over the last few
// minutes. Points are { t: ms timestamp, v: value }; x is time, so uneven
// sampling keeps its real spacing. The graph spans the points it has, up to
// `windowMs`.
// The y range always includes `ceiling` (e.g. a critical limit), so the line's
// height shows how close a reading is to it.
Canvas {
    id: root

    property var points: []
    property real windowMs: 5 * 60 * 1000
    property real floor: 30
    property real ceiling: 100
    property color color: Appearance.colors.green
    property color limitColor: Appearance.colors.red

    implicitWidth: 120
    implicitHeight: 28

    onPointsChanged: requestPaint()
    onColorChanged: requestPaint()
    onCeilingChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const pts = root.points || []
        if (pts.length === 0 || width <= 0 || height <= 0) return

        let lo = root.floor
        let hi = root.ceiling
        for (const p of pts) {
            lo = Math.min(lo, p.v - 2)
            hi = Math.max(hi, p.v + 2)
        }
        const span = Math.max(hi - lo, 1)
        const end = pts[pts.length - 1].t
        const start = Math.max(pts[0].t, end - root.windowMs)
        const range = Math.max(end - start, 1)
        const x = t => Math.max(0, (t - start) / range) * (width - 1)
        const y = v => (height - 2) - (v - lo) / span * (height - 4)

        // Critical limit
        ctx.strokeStyle = root.limitColor
        ctx.globalAlpha = 0.35
        ctx.lineWidth = 1
        ctx.setLineDash([2, 3])
        ctx.beginPath()
        ctx.moveTo(0, Math.round(y(root.ceiling)) + 0.5)
        ctx.lineTo(width, Math.round(y(root.ceiling)) + 0.5)
        ctx.stroke()
        ctx.setLineDash([])

        // Area under the line
        ctx.globalAlpha = 0.15
        ctx.fillStyle = root.color
        ctx.beginPath()
        ctx.moveTo(x(pts[0].t), height)
        for (const p of pts) ctx.lineTo(x(p.t), y(p.v))
        ctx.lineTo(x(end), height)
        ctx.closePath()
        ctx.fill()

        // Line
        ctx.globalAlpha = 1
        ctx.strokeStyle = root.color
        ctx.lineWidth = 1.5
        ctx.beginPath()
        for (let i = 0; i < pts.length; i++) {
            if (i === 0) ctx.moveTo(x(pts[i].t), y(pts[i].v))
            else ctx.lineTo(x(pts[i].t), y(pts[i].v))
        }
        if (pts.length === 1) ctx.lineTo(width - 1, y(pts[0].v))
        ctx.stroke()
    }
}
