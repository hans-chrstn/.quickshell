pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services.config
import qs.services.wallpaper

Singleton {
    id: root

    readonly property string cacheDirectory:
        Quickshell.cachePath("wallpaper-optimized")
    readonly property string recipeVersion: "h264-crf23-v2"
    readonly property int optimizationTimeout: 30 * 60 * 1000

    property bool directoryReady: false
    property bool directoryChecked: false
    property var records: ({})
    property string activeSource: ""
    property string activeTarget: ""
    property string activeOutput: ""
    property string activeTemporaryOutput: ""
    property bool activeOptimizeResolution: true
    property bool activeOptimizeFrameRate: true
    property bool activeOptimizeBitRate: true
    property int generation: 0
    property string clearState: "idle"
    property string clearError: ""

    readonly property bool busy: activeSource.length > 0
    readonly property bool clearing: clearProcess.running

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

    function recipeKey() {
        return recipeVersion
            + "|resolution=" + ConfigService.optimizeWallpaperResolution
            + "|fps=" + ConfigService.optimizeWallpaperFrameRate
            + "|bitrate=" + ConfigService.optimizeWallpaperBitRate
    }

    function outputPath(path, identity, width, height) {
        const key = Qt.md5(path + "|" + identity + "|" + recipeVersion
            + "|" + width + "x" + height + "|" + recipeKey())
        return cacheDirectory + "/" + key + ".mp4"
    }

    function targetDimensions(target) {
        let width = 0
        let height = 0
        for (const screen of Quickshell.screens) {
            if (target !== "All Displays" && screen.name !== target)
                continue
            const scale = Math.max(1, Number(screen.devicePixelRatio) || 1)
            width = Math.max(width, Math.round(screen.width * scale))
            height = Math.max(height, Math.round(screen.height * scale))
        }
        if (width <= 0 || height <= 0) {
            width = 1920
            height = 1080
        }
        // H.264/yuv420p requires even dimensions.
        return { width: width - width % 2, height: height - height % 2 }
    }

    function isOptimizedPath(path) {
        return String(path || "").startsWith(cacheDirectory + "/")
    }

    function desiredOutputPath(target, path) {
        const source = String(path || "")
        const identity = WallpaperProbeService.identityFor(source)
        if (identity.length === 0) return ""
        const size = targetDimensions(String(target || ""))
        return outputPath(source, identity, size.width, size.height)
    }

    function assignedPath(target) {
        return target === "All Displays"
            ? String(WallpaperAssignmentService.globalWallpaper || "")
            : String(WallpaperAssignmentService.wallpaperForScreen(target) || "")
    }

    function currentCopyAvailable(target, path) {
        const record = recordFor(path)
        const desired = desiredOutputPath(target, path)
        return desired.length > 0 && record.state === "ready"
            && record.outputPath === desired
    }

    function currentCopyApplied(target, path) {
        const desired = desiredOutputPath(target, path)
        return desired.length > 0 && assignedPath(target) === desired
    }

    function hasAssignedOptimizedCopy() {
        if (isOptimizedPath(WallpaperAssignmentService.globalWallpaper))
            return true
        const assignments = WallpaperAssignmentService.screenWallpapers
        for (const screenName in assignments) {
            if (isOptimizedPath(assignments[screenName]))
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

        const size = targetDimensions(String(target || ""))
        activeOptimizeResolution = ConfigService.optimizeWallpaperResolution
        activeOptimizeFrameRate = ConfigService.optimizeWallpaperFrameRate
        activeOptimizeBitRate = ConfigService.optimizeWallpaperBitRate
        activeSource = source
        activeTarget = String(target || "")
        activeOutput = outputPath(source, identity, size.width, size.height)
        activeTemporaryOutput = activeOutput + ".part.mp4"
        publish(source, { state: "preparing", outputPath: activeOutput })
        timeoutTimer.restart()
        tryStart()
        return true
    }

    function tryStart() {
        if (!busy || !directoryChecked || !WallpaperMediaTools.posterChecked)
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
        const size = targetDimensions(activeTarget)
        publish(activeSource, { state: "optimizing", outputPath: activeOutput })
        optimizeProcess.operationGeneration = generation
        let command = [
            WallpaperMediaTools.ffmpegPath, "-v", "error", "-y",
            "-i", activeSource, "-map", "0:v:0", "-an", "-sn", "-dn"
        ]
        const filters = []
        if (activeOptimizeResolution) {
            filters.push("scale='min(iw," + size.width + ")':'min(ih,"
                + size.height + ")':force_original_aspect_ratio=decrease")
        }
        filters.push("pad=ceil(iw/2)*2:ceil(ih/2)*2")
        if (activeOptimizeFrameRate)
            filters.push("fps=30")
        command = command.concat([
            "-vf", filters.join(","),
            "-c:v", "libx264", "-preset", "medium", "-crf", "23",
            "-pix_fmt", "yuv420p"
        ])
        if (activeOptimizeBitRate)
            command = command.concat(["-maxrate", "12M", "-bufsize", "24M"])
        optimizeProcess.command = command.concat([
            "-movflags", "+faststart", activeTemporaryOutput])
        optimizeProcess.running = true
    }

    function verifyOutput() {
        publish(activeSource, { state: "inspecting", outputPath: activeOutput })
        WallpaperProbeService.enqueue(activeOutput)
        inspectTimer.restart()
    }

    function applyOutput() {
        const source = activeSource
        const output = activeOutput
        const target = activeTarget
        const applied = target === "All Displays"
            ? WallpaperAssignmentService.setGlobal(output)
            : WallpaperAssignmentService.setForScreen(target, output)
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
    }

    function cancel() {
        if (!busy) return
        const source = activeSource
        generation += 1
        if (checkProcess.running) checkProcess.running = false
        if (optimizeProcess.running) optimizeProcess.running = false
        if (moveProcess.running) moveProcess.running = false
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
            if (record.state === "ready") root.applyOutput()
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
}
