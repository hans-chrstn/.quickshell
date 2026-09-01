pragma Singleton

import QtQuick
import Quickshell
import qs.services.power

Singleton {
    id: root

    function mediaSnapshot(path) {
        const media = WallpaperProbeService.recordFor(path)
        return {
            state: String(media?.state || "unknown"),
            codec: String(media?.codec || ""),
            container: String(media?.container || ""),
            width: Number(media?.width) || 0,
            height: Number(media?.height) || 0,
            durationMs: Number(media?.durationMs) || 0,
            frameRate: Number(media?.frameRate) || 0,
            bitRate: Number(media?.bitRate) || 0
        }
    }

    function optimizationSnapshot(path) {
        const currentPath = String(path || "")
        const records = WallpaperOptimizationService.records
        let sourcePath = currentPath
        let record = WallpaperOptimizationService.recordFor(currentPath)

        if (WallpaperOptimizationService.isOptimizedPath(currentPath)) {
            sourcePath = ""
            record = null
            for (const candidateSource in records) {
                const candidate = records[candidateSource]
                if (String(candidate.outputPath || "") === currentPath) {
                    sourcePath = candidateSource
                    record = candidate
                    break
                }
            }
        }

        const outputPath = String(record?.outputPath || "")
        const applied = WallpaperOptimizationService.isOptimizedPath(currentPath)
        const available = sourcePath.length > 0 && outputPath.length > 0
            && WallpaperProbeService.recordFor(outputPath).state === "ready"
        return {
            applied: applied,
            available: available,
            mappingKnown: sourcePath.length > 0,
            sourcePath: sourcePath,
            outputPath: outputPath,
            state: String(record?.state || (applied ? "unknown" : "idle")),
            error: String(record?.error || ""),
            sourceMedia: sourcePath.length > 0
                ? mediaSnapshot(sourcePath) : null,
            outputMedia: available ? mediaSnapshot(outputPath) : null
        }
    }

    function snapshot() {
        const now = Date.now()
        const renderers = WallpaperRenderService.snapshot()
        const occlusion = WallpaperOcclusionService.snapshot()
        const monitorPower = WallpaperMonitorPowerService.snapshot()
        const screens = ({})

        for (const screenName in renderers) {
            const renderer = renderers[screenName]
            screens[screenName] = {
                path: renderer.path,
                kind: renderer.kind,
                rendererState: renderer.state,
                error: renderer.error,
                decoderLoaded: renderer.decoderLoaded,
                decoderEvicted: renderer.decoderEvicted,
                playbackActive: renderer.playbackActive,
                suspended: renderer.suspended,
                suspendedReason: renderer.suspendedReason,
                activeDurationMs: WallpaperRenderService.activeDuration(
                    screenName, now),
                media: mediaSnapshot(renderer.path),
                optimization: optimizationSnapshot(renderer.path),
                occlusion: occlusion.screens?.[screenName] || null,
                monitorPowered: monitorPower.screens?.[screenName] !== false
            }
        }

        return {
            capturedAtMs: now,
            sessionLocal: true,
            collection: "on-demand",
            screens: screens,
            occlusionObserver: {
                observing: occlusion.observing,
                backend: occlusion.backend,
                samplingFloatingWindows: occlusion.samplingFloatingWindows,
                error: occlusion.error
            },
            monitorPowerObserver: {
                observing: monitorPower.observing,
                backend: monitorPower.backend,
                intervalMs: monitorPower.intervalMs,
                error: monitorPower.error
            },
            power: PowerStateService.snapshot()
        }
    }
}
