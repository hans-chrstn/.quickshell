pragma Singleton

import QtQuick
import Quickshell
import qs.services.hardware
import qs.services.wallpaper
import "WallpaperGuardrailPolicy.js" as GuardrailPolicy

Singleton {
    id: root

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
        const frameRate = Number(record.frameRate) || 0
        const bitRate = Number(record.bitRate) || 0
        const codec = String(record.codec || "").toLowerCase()
        const evaluation = VideoCapabilityService.codecEvaluations.find(
            candidate => String(candidate.codec || "") === codec) || ({})
        const policy = GuardrailPolicy.assess(record, {
            decodeProfileVerified:
                VideoCapabilityService.verifiedDecodeCodecs.indexOf(codec) >= 0,
            pipelineAccepted: evaluation.measurementAccepted === true
        })

        return {
            target: String(target || ""),
            path: String(path || ""),
            state: String(record.state || "unknown"),
            kind: String(record.kind || "unsupported"),
            width: Number(record.width) || 0,
            height: Number(record.height) || 0,
            frameRate: frameRate,
            bitRate: bitRate,
            codec: codec,
            severity: policy.severity,
            issues: policy.issues,
            hardwareState: policy.hardwareState
        }
    }

    function snapshot() {
        return assignedAssessments
    }
}
