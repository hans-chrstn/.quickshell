pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services.config
import qs.services.hardware
import qs.services.jobs
import qs.services.wallpaper
import "VideoOptimizationCodec.js" as OptimizationCodec
import "WallpaperRecipeSummary.js" as RecipeSummary
import "WallpaperTargetGeometry.js" as TargetGeometry

Singleton {
    id: root

    readonly property string cacheDirectory:
        Quickshell.cachePath("wallpaper-optimized")
    readonly property string recipeVersion: selectedCodecRecipe().version
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
    property var resolutionSelections: ({})
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

    readonly property var resolutionScales: [0.5, 1, 1.5]
    readonly property real resolutionCustomStep: 0.05
    readonly property int maximumOutputWidth: 3840
    readonly property int maximumOutputHeight: 2160
    readonly property var frameRatePresets: [15, 24, 30]
    readonly property real frameRateCustomStep: 1
    readonly property var bitRatePresets: [4, 8, 12]
    readonly property real bitRateCustomStep: 0.5

    function sourceFrameRate(path) {
        return Math.max(0, Number(
            WallpaperProbeService.recordFor(path).frameRate) || 0)
    }

    function sourceBitRateMbps(path) {
        return Math.max(0, Number(
            WallpaperProbeService.recordFor(path).bitRate) || 0) / 1000000
    }

    function settingsMaximumMediaValue(field, fallback) {
        const assessments = WallpaperGuardrailService.assignedAssessments
        let maximum = Infinity
        let inspected = 0
        for (const assessment of assessments) {
            if (assessment.kind !== "video"
                    || isOptimizedPath(assessment.path))
                continue
            const value = field === "frameRate"
                ? Number(assessment.frameRate) || 0
                : (Number(assessment.bitRate) || 0) / 1000000
            if (value <= 0)
                continue
            maximum = Math.min(maximum, value)
            inspected += 1
        }
        return inspected > 0 ? maximum : fallback
    }

    function settingsMaximumFrameRate() {
        return settingsMaximumMediaValue("frameRate", 30)
    }

    function settingsMaximumBitRate() {
        return settingsMaximumMediaValue("bitRate", 12)
    }

    function frameRateMode() {
        return ConfigService.optimizeWallpaperFrameRateCustom
            ? -1 : ConfigService.optimizeWallpaperFrameRateLimit
    }

    function bitRateMode() {
        return ConfigService.optimizeWallpaperBitRateCustom
            ? -1 : ConfigService.optimizeWallpaperBitRateLimit
    }

    function availableModes(presets, maximum) {
        const modes = presets.filter(value => value <= maximum + 0.0001)
        if (maximum >= 0.5)
            modes.push(-1)
        return modes
    }

    function settingsFrameRateModes() {
        return availableModes(frameRatePresets, settingsMaximumFrameRate())
    }

    function settingsBitRateModes() {
        return availableModes(bitRatePresets, settingsMaximumBitRate())
    }

    function setFrameRateMode(mode) {
        const value = Number(mode)
        if (value === -1) {
            ConfigService.setSettings({
                optimizeWallpaperFrameRate: true,
                optimizeWallpaperFrameRateCustom: true,
                optimizeWallpaperFrameRateCustomLimit: Math.min(
                    ConfigService.optimizeWallpaperFrameRateCustomLimit,
                    settingsMaximumFrameRate())
            })
            return true
        }
        if (frameRatePresets.indexOf(value) < 0
                || settingsFrameRateModes().indexOf(value) < 0)
            return false
        ConfigService.setSettings({
            optimizeWallpaperFrameRate: true,
            optimizeWallpaperFrameRateCustom: false,
            optimizeWallpaperFrameRateLimit: value
        })
        return true
    }

    function setBitRateMode(mode) {
        const value = Number(mode)
        if (value === -1) {
            ConfigService.setSettings({
                optimizeWallpaperBitRate: true,
                optimizeWallpaperBitRateCustom: true,
                optimizeWallpaperBitRateCustomLimit: Math.min(
                    ConfigService.optimizeWallpaperBitRateCustomLimit,
                    settingsMaximumBitRate())
            })
            return true
        }
        if (bitRatePresets.indexOf(value) < 0
                || settingsBitRateModes().indexOf(value) < 0)
            return false
        ConfigService.setSettings({
            optimizeWallpaperBitRate: true,
            optimizeWallpaperBitRateCustom: false,
            optimizeWallpaperBitRateLimit: value
        })
        return true
    }

    function setCustomFrameRate(value) {
        return ConfigService.setSetting("optimizeWallpaperFrameRateCustomLimit",
            Math.max(1, Math.min(Number(value) || 1,
                Math.max(1, settingsMaximumFrameRate()))))
    }

    function setCustomBitRate(value) {
        return ConfigService.setSetting("optimizeWallpaperBitRateCustomLimit",
            Math.max(0.5, Math.min(Number(value) || 0.5,
                Math.max(0.5, settingsMaximumBitRate()))))
    }

    function selectedFrameRate(path) {
        const configured = ConfigService.optimizeWallpaperFrameRateCustom
            ? ConfigService.optimizeWallpaperFrameRateCustomLimit
            : ConfigService.optimizeWallpaperFrameRateLimit
        const maximum = sourceFrameRate(path)
        return maximum > 0 ? Math.min(configured, maximum) : configured
    }

    function selectedBitRate(path) {
        const configured = ConfigService.optimizeWallpaperBitRateCustom
            ? ConfigService.optimizeWallpaperBitRateCustomLimit
            : ConfigService.optimizeWallpaperBitRateLimit
        const maximum = sourceBitRateMbps(path)
        return maximum > 0 ? Math.min(configured, maximum) : configured
    }

    function selectedCodecRecipe() {
        return OptimizationCodec.recipe(
            VideoCapabilityService.optimizationCandidate)
    }

    function maximumResolutionScale(target, path) {
        const media = WallpaperProbeService.recordFor(path)
        const sourceWidth = Math.max(0, Number(media.width) || 0)
        const sourceHeight = Math.max(0, Number(media.height) || 0)
        if (sourceWidth <= 0 || sourceHeight <= 0)
            return 4
        const targetSize = targetDimensions(String(target || ""))
        if (!targetSize.available)
            return 0
        const targetScalePerMultiplier = Math.min(
            targetSize.width / sourceWidth,
            targetSize.height / sourceHeight)
        if (targetScalePerMultiplier <= 0)
            return 0
        const maximumSourceScale = Math.min(1,
            maximumOutputWidth / sourceWidth,
            maximumOutputHeight / sourceHeight)
        const ratio = Math.min(4,
            maximumSourceScale / targetScalePerMultiplier)
        return Math.max(0, Math.floor((ratio + 0.0001)
            / resolutionCustomStep) * resolutionCustomStep)
    }

    function recipeKey(path, resolutionScale) {
        const codecRecipe = selectedCodecRecipe()
        return codecRecipe.version
            + "|codec=" + codecRecipe.codec
            + "|encoder=" + codecRecipe.encoder
            + "|resolution=" + (ConfigService.optimizeWallpaperResolution
                ? resolutionScale : "off")
            + "|fps=" + selectedFrameRate(path)
            + "|bitrate=" + selectedBitRate(path)
    }

    function outputPath(path, identity, width, height, resolutionScale) {
        const key = Qt.md5(path + "|" + identity
            + "|" + width + "x" + height + "|"
            + recipeKey(path, resolutionScale))
        return cacheDirectory + "/" + key + ".mp4"
    }

    function targetDimensions(target) {
        return TargetGeometry.physicalDimensions(
            Quickshell.screens, String(target || ""))
    }

    function isOptimizedPath(path) {
        return String(path || "").startsWith(cacheDirectory + "/")
    }

    function selectionKey(target, path) {
        return String(target || "") + "|" + String(path || "")
    }

    function candidateDimensions(target, path, multiplier) {
        const media = WallpaperProbeService.recordFor(path)
        const sourceWidth = Math.max(0, Number(media.width) || 0)
        const sourceHeight = Math.max(0, Number(media.height) || 0)
        if (sourceWidth <= 0 || sourceHeight <= 0)
            return { width: 0, height: 0, scale: 0 }
        const targetSize = targetDimensions(String(target || ""))
        if (!targetSize.available)
            return { width: 0, height: 0, scale: 0 }
        const factor = Number(multiplier) || 0
        const scale = Math.min(1,
            targetSize.width * factor / sourceWidth,
            targetSize.height * factor / sourceHeight)
        return {
            width: Math.max(2, Math.floor(sourceWidth * scale / 2) * 2),
            height: Math.max(2, Math.floor(sourceHeight * scale / 2) * 2),
            scale: scale
        }
    }

    function scaleAvailable(target, path, multiplier) {
        const factor = Number(multiplier)
        if (!Number.isFinite(factor) || factor < 0.5)
            return false
        if (factor > maximumResolutionScale(target, path) + 0.0001)
            return false
        const candidate = candidateDimensions(target, path, multiplier)
        return candidate.width > 0 && candidate.height > 0
    }

    function availableResolutionScales(target, path) {
        return resolutionScales.filter(multiplier =>
            scaleAvailable(target, path, multiplier))
    }

    function settingsResolutionScales() {
        const assessments = WallpaperGuardrailService.assignedAssessments
        let available = resolutionScales.slice()
        let inspected = 0
        for (const assessment of assessments) {
            if (assessment.kind !== "video"
                    || isOptimizedPath(assessment.path))
                continue
            const sourceAvailable = availableResolutionScales(
                assessment.target, assessment.path)
            available = available.filter(value =>
                sourceAvailable.indexOf(value) >= 0)
            inspected += 1
        }
        return inspected > 0 ? available : resolutionScales
    }

    function settingsMaximumResolutionScale() {
        const assessments = WallpaperGuardrailService.assignedAssessments
        let maximum = 4
        let inspected = 0
        for (const assessment of assessments) {
            if (assessment.kind !== "video"
                    || isOptimizedPath(assessment.path))
                continue
            maximum = Math.min(maximum, maximumResolutionScale(
                assessment.target, assessment.path))
            inspected += 1
        }
        return inspected > 0 ? maximum : 1.5
    }

    function resolutionMode() {
        if (!ConfigService.optimizeWallpaperResolution)
            return 0
        return ConfigService.optimizeWallpaperResolutionCustom
            ? -1 : ConfigService.optimizeWallpaperResolutionScale
    }

    function settingsResolutionModes() {
        const modes = [0]
        for (const scale of settingsResolutionScales())
            modes.push(scale)
        if (settingsMaximumResolutionScale() >= 0.5)
            modes.push(-1)
        return modes
    }

    function setResolutionMode(mode) {
        const value = Number(mode)
        if (value === 0) {
            ConfigService.setSettings({
                optimizeWallpaperResolution: false,
                optimizeWallpaperResolutionCustom: false
            })
            return true
        }
        if (value === -1) {
            ConfigService.setSettings({
                optimizeWallpaperResolution: true,
                optimizeWallpaperResolutionCustom: true,
                optimizeWallpaperResolutionCustomScale:
                    Math.min(ConfigService.optimizeWallpaperResolutionCustomScale,
                        settingsMaximumResolutionScale())
            })
            return true
        }
        if (settingsResolutionScales().indexOf(value) < 0)
            return false
        ConfigService.setSettings({
            optimizeWallpaperResolution: true,
            optimizeWallpaperResolutionCustom: false,
            optimizeWallpaperResolutionScale: value
        })
        return true
    }

    function setCustomResolutionScale(value) {
        const clamped = Math.max(0.5, Math.min(Number(value) || 0.5,
            Math.max(0.5, settingsMaximumResolutionScale())))
        return ConfigService.setSetting(
            "optimizeWallpaperResolutionCustomScale", clamped)
    }

    function setDefaultResolutionScale(multiplier) {
        const value = Number(multiplier)
        if (settingsResolutionScales().indexOf(value) < 0)
            return false
        return ConfigService.setSetting(
            "optimizeWallpaperResolutionScale", value)
    }

    function selectedResolutionScale(target, path) {
        const key = selectionKey(target, path)
        const configured = ConfigService.optimizeWallpaperResolutionCustom
            ? ConfigService.optimizeWallpaperResolutionCustomScale
            : ConfigService.optimizeWallpaperResolutionScale
        const selected = Number(resolutionSelections[key] ?? configured)
        const maximum = maximumResolutionScale(target, path)
        return ConfigService.optimizeWallpaperResolutionCustom && maximum >= 0.5
            ? Math.min(selected, maximum) : selected
    }

    function setResolutionScale(target, path, multiplier) {
        const value = Number(multiplier)
        if (!scaleAvailable(target, path, value))
            return false
        const updated = Object.assign({}, resolutionSelections)
        updated[selectionKey(target, path)] = value
        resolutionSelections = updated
        ConfigService.setSetting("optimizeWallpaperResolutionScale", value)
        return true
    }

    function desiredOutputPath(target, path) {
        const source = String(path || "")
        const identity = WallpaperProbeService.identityFor(source)
        if (identity.length === 0) return ""
        const size = targetDimensions(String(target || ""))
        if (!size.available)
            return ""
        const scale = selectedResolutionScale(target, path)
        return outputPath(source, identity, size.width, size.height, scale)
    }

    function recipeSnapshot(target, path) {
        const source = String(path || "")
        const scale = selectedResolutionScale(target, source)
        const size = targetDimensions(String(target || ""))
        const dimensions = ConfigService.optimizeWallpaperResolution
            ? candidateDimensions(target, source, scale)
            : {
                width: Number(WallpaperProbeService.recordFor(source).width) || 0,
                height: Number(WallpaperProbeService.recordFor(source).height) || 0,
                scale: 1
            }
        const codecRecipe = selectedCodecRecipe()
        return {
            source: source,
            target: String(target || ""),
            key: recipeKey(source, scale),
            desiredOutput: desiredOutputPath(target, source),
            resolutionMode: resolutionMode(),
            resolutionScale: ConfigService.optimizeWallpaperResolution
                ? scale : "native",
            outputWidth: dimensions.width,
            outputHeight: dimensions.height,
            codec: codecRecipe.codec,
            encoder: codecRecipe.encoder,
            codecSelectionReason:
                VideoCapabilityService.optimizationCandidate.selectionReason,
            frameRate: selectedFrameRate(source),
            bitRateMbps: selectedBitRate(source),
            audioRemoved: true,
            targetWidth: size.width,
            targetHeight: size.height,
            targetAvailable: size.available,
            targetError: size.error
        }
    }

    function recipeDescription(target, path) {
        return RecipeSummary.describe(recipeSnapshot(target, path))
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
        if (!size.available) {
            publish(source, { state: "failed", error: size.error })
            return false
        }
        const resolutionScale = selectedResolutionScale(target, source)
        if (ConfigService.optimizeWallpaperResolution
                && !scaleAvailable(target, source, resolutionScale)) {
            publish(source, { state: "failed",
                error: "Select a resolution multiplier below the source size" })
            return false
        }
        activeOptimizeResolution = ConfigService.optimizeWallpaperResolution
        activeResolutionScale = resolutionScale
        activeOptimizeFrameRate = true
        activeFrameRateLimit = selectedFrameRate(source)
        activeOptimizeBitRate = true
        activeBitRateLimit = selectedBitRate(source)
        const codecRecipe = selectedCodecRecipe()
        activeCodec = codecRecipe.codec
        activeEncoder = codecRecipe.encoder
        activeCodecArguments = codecRecipe.arguments.slice()
        activeSource = source
        activeTarget = String(target || "")
        activeOutput = outputPath(source, identity, size.width, size.height,
            resolutionScale)
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
        const size = targetDimensions(activeTarget)
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
            const limit = candidateDimensions(activeTarget, activeSource,
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
