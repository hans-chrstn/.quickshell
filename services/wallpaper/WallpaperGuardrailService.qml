pragma Singleton

import QtQuick
import Quickshell
import qs.services.wallpaper

Singleton {
    id: root

    readonly property real fourKPixels: 3840 * 2160
    readonly property real eightKPixels: 7680 * 4320
    readonly property real advisoryBitRate: 20000000
    readonly property real highBitRate: 50000000

    readonly property var assignedAssessments: {
        WallpaperProbeService.records
        const result = []
        const seen = ({})
        const globalPath = String(WallpaperAssignmentService.globalWallpaper || "")
        if (globalPath.length > 0) {
            seen[globalPath] = true
            result.push(assessment("All Displays", globalPath))
        }
        const overrides = WallpaperAssignmentService.screenWallpapers
        for (const screenName in overrides) {
            const path = String(overrides[screenName] || "")
            if (path.length === 0)
                continue
            result.push(assessment(screenName, path))
        }
        return result
    }

    function assessment(target, path) {
        const record = WallpaperProbeService.recordFor(path)
        const issues = []
        let severity = 0
        const pixels = Number(record.width) * Number(record.height)
        const frameRate = Number(record.frameRate) || 0
        const bitRate = Number(record.bitRate) || 0

        function add(level, message) {
            severity = Math.max(severity, level)
            issues.push(message)
        }

        if (record.state === "ready" && record.kind === "video") {
            if (pixels >= eightKPixels)
                add(2, "8K-class resolution can require substantial decode memory")
            else if (pixels >= fourKPixels)
                add(frameRate > 30 ? 2 : 1,
                    "4K-class video increases decoder and memory-bandwidth cost")

            if (frameRate > 60)
                add(2, "Frame rate above 60 FPS is unusually expensive")
            else if (frameRate > 30)
                add(1, "Frame rate above 30 FPS increases continuous decode work")

            if (bitRate >= highBitRate)
                add(2, "Bitrate above 50 Mbps increases decode and I/O pressure")
            else if (bitRate >= advisoryBitRate)
                add(1, "Bitrate above 20 Mbps may increase decode and I/O pressure")

            if (["hevc", "av1"].indexOf(String(record.codec)) >= 0)
                add(1, String(record.codec).toUpperCase()
                    + " efficiency depends strongly on hardware decoding")
        }

        return {
            target: String(target || ""),
            path: String(path || ""),
            state: String(record.state || "unknown"),
            kind: String(record.kind || "unsupported"),
            width: Number(record.width) || 0,
            height: Number(record.height) || 0,
            frameRate: frameRate,
            bitRate: bitRate,
            codec: String(record.codec || ""),
            severity: severity,
            issues: issues
        }
    }

    function snapshot() {
        return assignedAssessments
    }
}
