pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services.config
import qs.services.jobs
import qs.services.wallpaper

Singleton {
    id: root

    readonly property string cacheDirectory:
        Quickshell.cachePath("wallpaper-optimized")
    readonly property int optimizationTimeout: 30 * 60 * 1000

    property bool directoryReady: false
    property bool directoryChecked: false
    property var records: ({})
    property string activeSource: ""
    property string activeTarget: ""
    property string activeOutput: ""
    property string activeTemporaryOutput: ""
    property bool activeOptimizeResolution: true
    property real activeResolutionScale: 1
    property bool activeOptimizeFrameRate: true
    property real activeFrameRateLimit: 30
    property bool activeOptimizeBitRate: true
    property real activeBitRateLimit: 12
    property string activeCodec: "h264"
    property string activeEncoder: "libx264"
    property var activeCodecArguments: []
    property int generation: 0
    property string clearState: "idle"
    property string clearError: ""

    readonly property bool busy: activeSource.length > 0
    readonly property bool clearing: clearProcess.running

    function discardTemporaryOutput(path) {
        const temporary = String(path || "")
        if (!temporary.startsWith(cacheDirectory + "/")
                || !temporary.endsWith(".part.mp4"))
            return false
        temporaryCleanupProcess.command = ["rm", "-f", "--", temporary]
        temporaryCleanupProcess.running = true
        return true
    }

    function emptyRecord(path) {
        return {
            sourcePath: String(path || ""),
            outputPath: "",
            state: "idle",
            progress: -1,
            error: ""
        }
    }

    function recordFor(path) {
        return records[String(path || "")] || emptyRecord(path)
    }

    function publish(path, values) {
        const updated = ({})
        for (const key in records)
            updated[key] = records[key]
        updated[path] = Object.assign(emptyRecord(path), values)
        records = updated
    }


    function assignedPath(target) {
        return target === "All Displays"
            ? String(WallpaperAssignmentService.globalWallpaper || "")
            : String(WallpaperAssignmentService.wallpaperForScreen(target) || "")
    }

    function currentCopyAvailable(target, path) {
        const record = recordFor(path)
        const desired = WallpaperOptimizationPolicyService.desiredOutputPath(
            target, path)
        return desired.length > 0 && record.state === "ready"
            && record.outputPath === desired
    }

    function currentCopyApplied(target, path) {
        const desired = WallpaperOptimizationPolicyService.desiredOutputPath(
            target, path)
        return desired.length > 0 && assignedPath(target) === desired
    }

    function hasAssignedOptimizedCopy() {
        if (WallpaperOptimizationPolicyService.isOptimizedPath(
                WallpaperAssignmentService.globalWallpaper))
            return true
        const assignments = WallpaperAssignmentService.screenWallpapers
        for (const screenName in assignments) {
            if (WallpaperOptimizationPolicyService.isOptimizedPath(
                    assignments[screenName]))
                return true
        }
        return false
    }

    function clearCache() {
        if (busy || clearing) {
            clearState = "failed"
            clearError = "Wait for wallpaper optimization to finish"
            return false
        }
        if (hasAssignedOptimizedCopy()) {
            clearState = "failed"
            clearError = "Select original wallpapers before clearing the cache"
            return false
        }
        if (!directoryReady) {
            clearState = "failed"
            clearError = "Optimization cache is unavailable"
            return false
        }
        clearState = "clearing"
        clearError = ""
        clearProcess.command = ["find", cacheDirectory, "-mindepth", "1",
            "-maxdepth", "1", "-type", "f", "-delete"]
        clearProcess.running = true
        return true
    }

    function cacheSnapshot() {
        return {
            directory: cacheDirectory,
            busy: busy,
            clearing: clearing,
            assignedCopyProtected: hasAssignedOptimizedCopy(),
            clearState: clearState,
            error: clearError
        }
    }

    function request(target, path) {
        const source = String(path || "")
        const media = WallpaperProbeService.recordFor(source)
        if (!ConfigService.allowWallpaperOptimization) {
            publish(source, { state: "failed",
                error: "Wallpaper optimization is disabled" })
            return false
        }
        if (busy) {
            publish(source, { state: "failed",
                error: "Another wallpaper optimization is already running" })
            return false
        }
        if (media.state !== "ready" || media.kind !== "video") {
            publish(source, { state: "failed",
                error: "Only inspected video wallpapers can be optimized" })
            return false
        }
        const identity = WallpaperProbeService.identityFor(source)
        if (identity.length === 0) {
            publish(source, { state: "failed",
                error: "Wallpaper identity is unavailable" })
            return false
        }

        const size = WallpaperOptimizationPolicyService.targetDimensions(
            String(target || ""))
        if (!size.available) {
            publish(source, { state: "failed", error: size.error })
            return false
        }
        const resolutionScale = WallpaperOptimizationPolicyService
            .selectedResolutionScale(target, source)
        if (ConfigService.optimizeWallpaperResolution
                && !WallpaperOptimizationPolicyService.scaleAvailable(
                    target, source, resolutionScale)) {
            publish(source, { state: "failed",
                error: "Select a resolution multiplier below the source size" })
            return false
        }
        activeOptimizeResolution = ConfigService.optimizeWallpaperResolution
        activeResolutionScale = resolutionScale
        activeOptimizeFrameRate = true
        activeFrameRateLimit = WallpaperOptimizationPolicyService
            .selectedFrameRate(source)
        activeOptimizeBitRate = true
        activeBitRateLimit = WallpaperOptimizationPolicyService
            .selectedBitRate(source)
        const codecRecipe = WallpaperOptimizationPolicyService
            .selectedCodecRecipe()
        activeCodec = codecRecipe.codec
        activeEncoder = codecRecipe.encoder
        activeCodecArguments = codecRecipe.arguments.slice()
        activeSource = source
        activeTarget = String(target || "")
        activeOutput = WallpaperOptimizationPolicyService.outputPath(
            source, identity, size.width, size.height, resolutionScale)
        activeTemporaryOutput = activeOutput + ".part.mp4"
        publish(source, { state: "preparing", outputPath: activeOutput })
        timeoutTimer.restart()
        tryStart()
        return true
    }

    function tryStart() {
        if (!busy || !directoryChecked || !WallpaperMediaTools.posterChecked
                || !BackgroundJobTools.ready)
            return
        if (!directoryReady || WallpaperMediaTools.ffmpegPath.length === 0) {
            publish(activeSource, { state: "failed", outputPath: activeOutput,
                error: !directoryReady ? "Optimization cache is unavailable"
                    : "FFmpeg is unavailable" })
            finish()
            return
        }
        publish(activeSource, { state: "checking", outputPath: activeOutput })
        checkProcess.operationGeneration = generation
        checkProcess.command = ["stat", "--printf=%s", "--", activeOutput]
        checkProcess.running = true
    }

    function generate() {
        const size = WallpaperOptimizationPolicyService.targetDimensions(
            activeTarget)
        if (!size.available) {
            publish(activeSource, { state: "failed", outputPath: activeOutput,
                error: size.error })
            discardTemporaryOutput(activeTemporaryOutput)
            finish()
            return
        }
        publish(activeSource, { state: "optimizing", outputPath: activeOutput })
        optimizeProcess.operationGeneration = generation
        let command = [
            WallpaperMediaTools.ffmpegPath, "-v", "error", "-y",
            "-i", activeSource, "-map", "0:v:0", "-an", "-sn", "-dn",
            "-map_metadata", "-1", "-map_chapters", "-1"
        ]
        const filters = []
        if (activeOptimizeResolution) {
            const width = Math.round(size.width * activeResolutionScale)
            const height = Math.round(size.height * activeResolutionScale)
            filters.push("scale='min(iw," + width + ")':'min(ih,"
                + height + ")':force_original_aspect_ratio=decrease")
        }
        filters.push("pad=ceil(iw/2)*2:ceil(ih/2)*2")
        if (activeOptimizeFrameRate)
            filters.push("fps=" + activeFrameRateLimit)
        command = command.concat(["-vf", filters.join(",")])
            .concat(activeCodecArguments)
        if (activeOptimizeBitRate) {
            command = command.concat(["-maxrate", activeBitRateLimit + "M",
                "-bufsize", (activeBitRateLimit * 2) + "M"])
        }
        optimizeProcess.command = BackgroundJobTools.wrap(command.concat([
            "-movflags", "+faststart", activeTemporaryOutput]))
        optimizeProcess.running = true
    }

    function verifyOutput() {
        publish(activeSource, { state: "inspecting", outputPath: activeOutput })
        WallpaperProbeService.enqueue(activeOutput)
        inspectTimer.restart()
    }

    function outputValid(record) {
        if (activeOptimizeResolution) {
            const limit = WallpaperOptimizationPolicyService
                .candidateDimensions(activeTarget, activeSource,
                    activeResolutionScale)
            if (record.width > limit.width || record.height > limit.height)
                return false
        }
        if (activeOptimizeFrameRate && Number(record.frameRate)
                > activeFrameRateLimit + 0.05)
            return false
        if (activeOptimizeBitRate && Number(record.bitRate) > 0
                && Number(record.bitRate)
                    > activeBitRateLimit * 1000000 * 1.05)
            return false
        return record.codec === activeCodec
    }

    function applyOutput() {
        const source = activeSource
        const output = activeOutput
        const target = activeTarget
        const applied = target === "All Displays"
            ? WallpaperAssignmentService.setGlobal(output, false)
            : WallpaperAssignmentService.setForScreen(target, output, false)
        publish(source, {
            state: applied ? "ready" : "failed",
            outputPath: output,
            error: applied ? "" : WallpaperAssignmentService.error
        })
        finish()
    }

    function finish() {
        timeoutTimer.stop()
        inspectTimer.stop()
        activeSource = ""
        activeTarget = ""
        activeOutput = ""
        activeTemporaryOutput = ""
        activeCodec = "h264"
        activeEncoder = "libx264"
        activeCodecArguments = []
    }

    function cancel() {
        if (!busy) return
        const source = activeSource
        const temporary = activeTemporaryOutput
        generation += 1
        if (checkProcess.running) checkProcess.running = false
        if (optimizeProcess.running) optimizeProcess.running = false
        if (moveProcess.running) moveProcess.running = false
        discardTemporaryOutput(temporary)
        publish(source, { state: "cancelled", error: "Optimization cancelled" })
        finish()
    }

    Component.onCompleted: {
        directoryProcess.command = ["mkdir", "-p", "--", cacheDirectory]
        directoryProcess.running = true
    }

    Connections {
        target: WallpaperMediaTools
        function onPosterCheckedChanged() { root.tryStart() }
    }

    Connections {
        target: BackgroundJobTools
        function onReadyChanged() { root.tryStart() }
    }

    Connections {
        target: ConfigService
        function onAllowWallpaperOptimizationChanged() {
            if (!ConfigService.allowWallpaperOptimization)
                root.cancel()
        }
    }

    Connections {
        target: WallpaperProbeService
        function onRecordsChanged() {
            if (root.activeOutput.length === 0) return
            const record = WallpaperProbeService.recordFor(root.activeOutput)
            if (record.state === "ready") {
                if (root.outputValid(record)) root.applyOutput()
                else {
                    root.publish(root.activeSource, { state: "failed",
                        outputPath: root.activeOutput,
                        error: "Optimized wallpaper failed policy verification" })
                    root.finish()
                }
            }
            else if (["failed", "unsupported"].indexOf(record.state) >= 0) {
                root.publish(root.activeSource, { state: "failed",
                    outputPath: root.activeOutput,
                    error: "Optimized wallpaper could not be verified" })
                root.finish()
            }
        }
    }

    Timer {
        id: timeoutTimer
        interval: root.optimizationTimeout
        onTriggered: {
            const source = root.activeSource
            root.cancel()
            root.publish(source, { state: "failed",
                error: "Wallpaper optimization timed out" })
        }
    }

    Timer {
        id: inspectTimer
        interval: 10000
        onTriggered: {
            const source = root.activeSource
            root.publish(source, { state: "failed",
                outputPath: root.activeOutput,
                error: "Optimized wallpaper verification timed out" })
            root.finish()
        }
    }

    Process {
        id: directoryProcess
        onExited: exitCode => {
            root.directoryReady = exitCode === 0
            root.directoryChecked = true
            root.tryStart()
        }
    }

    Process {
        id: checkProcess
        property int operationGeneration: 0
        property string output: ""
        stdout: StdioCollector { onStreamFinished: checkProcess.output = text }
        onStarted: output = ""
        onExited: exitCode => {
            if (operationGeneration !== root.generation || !root.busy) return
            if (exitCode === 0 && Number(output) > 0)
                root.verifyOutput()
            else
                root.generate()
        }
    }

    Process {
        id: optimizeProcess
        property int operationGeneration: 0
        onExited: exitCode => {
            if (operationGeneration !== root.generation || !root.busy) return
            if (exitCode !== 0) {
                root.discardTemporaryOutput(root.activeTemporaryOutput)
                root.publish(root.activeSource, { state: "failed",
                    outputPath: root.activeOutput,
                    error: "Wallpaper optimization failed" })
                root.finish()
                return
            }
            moveProcess.operationGeneration = operationGeneration
            moveProcess.command = ["mv", "--", root.activeTemporaryOutput,
                root.activeOutput]
            moveProcess.running = true
        }
    }

    Process {
        id: moveProcess
        property int operationGeneration: 0
        onExited: exitCode => {
            if (operationGeneration !== root.generation || !root.busy) return
            if (exitCode === 0) root.verifyOutput()
            else {
                root.publish(root.activeSource, { state: "failed",
                    outputPath: root.activeOutput,
                    error: "Optimized wallpaper could not be finalized" })
                root.finish()
            }
        }
    }

    Process {
        id: clearProcess
        onExited: exitCode => {
            if (exitCode === 0) {
                root.records = ({})
                root.clearState = "ready"
                root.clearError = ""
            } else {
                root.clearState = "failed"
                root.clearError = "Optimization cache could not be cleared"
            }
        }
    }

    Process {
        id: temporaryCleanupProcess
    }
}
