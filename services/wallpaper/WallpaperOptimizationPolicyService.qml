pragma Singleton

import QtQuick
import Quickshell
import qs.services.config
import qs.services.hardware
import qs.services.wallpaper
import "VideoOptimizationCodec.js" as OptimizationCodec
import "WallpaperRecipeSummary.js" as RecipeSummary
import "WallpaperTargetGeometry.js" as TargetGeometry

Singleton {
    id: root

    readonly property string cacheDirectory:
        Quickshell.cachePath("wallpaper-optimized")
    readonly property string recipeVersion: selectedCodecRecipe().version
    property var resolutionSelections: ({})

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
}
