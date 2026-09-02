import QtQuick
import Quickshell
import Quickshell.Io
import qs.services.analytics
import qs.services.config
import qs.services.display
import qs.services.hardware
import qs.services.launcher
import qs.services.lifecycle
import qs.services.jobs
import qs.services.power
import qs.services.session
import qs.services.settings
import qs.services.time
import qs.services.wallpaper
import "JsonFormat.js" as JsonFormat

IpcHandler {
    target: "new-shell"

    function launcher(): void { LauncherService.toggle() }
    function launcherOpen(query: string): void { LauncherService.open(query) }
    function launcherClose(): void { LauncherService.close() }
    function session(): void { SessionService.toggle() }
    function sessionOpen(): void { SessionService.open() }
    function sessionClose(): void { SessionService.close() }
    function sessionLockStatus(): string {
        return JsonFormat.stringify(SessionLockService.snapshot())
    }
    function sessionSetTestState(locked: bool,
            preparingForSleep: bool): bool {
        return SessionLockService.setTestState(locked, preparingForSleep)
    }
    function sessionClearTestState(): bool {
        return SessionLockService.clearTestState()
    }
    function powerStatus(): string {
        return JsonFormat.stringify(PowerStateService.snapshot())
    }
    function powerTestSet(available: bool, onBattery: bool,
            percentage: real): bool {
        return PowerStateService.setSyntheticState(
            available, onBattery, percentage)
    }
    function powerTestClear(): bool {
        return PowerStateService.clearSyntheticState()
    }
    function settings(): void { SettingsService.toggle() }
    function settingsOpen(): void { SettingsService.open() }
    function settingsOpenCategory(category: string): bool {
        return SettingsService.openCategory(category)
    }
    function settingsOpenPage(page: string): bool {
        return SettingsService.openPage(page)
    }
    function settingsBack(): bool { return SettingsService.back() }
    function settingsSet(key: string, value: string): bool {
        return ConfigService.setSetting(key, value)
    }
    function settingsStatus(): string {
        return JsonFormat.stringify(SettingsService.snapshot())
    }
    function configStatus(): string {
        return JsonFormat.stringify(ConfigService.snapshot())
    }
    function clockStatus(): string {
        return JsonFormat.stringify(ClockService.snapshot())
    }
    function displayActivityStatus(): string {
        return JsonFormat.stringify(DisplayActivityService.snapshot())
    }
    function displayActivityTestSetIdle(idle: bool): bool {
        return DisplayActivityService.setSyntheticIdle(idle)
    }
    function displayActivityTestClear(): bool {
        return DisplayActivityService.clearSyntheticIdle()
    }
    function lifecycleStatus(): string {
        return JsonFormat.stringify(LifecycleService.snapshot())
    }
    function performanceStatus(): string {
        return JsonFormat.stringify(PerformanceAnalyticsService.snapshot())
    }
    function backgroundJobStatus(): string {
        return JsonFormat.stringify(BackgroundJobTools.snapshot())
    }
    function videoCapabilitiesRefresh(): bool {
        return VideoCapabilityService.refresh()
    }
    function videoCapabilitiesStatus(): string {
        return JsonFormat.stringify(VideoCapabilityService.snapshot())
    }
    function videoCodecBenchmarkStart(path: string): bool {
        return VideoCodecBenchmarkService.request(path)
    }
    function videoCodecBenchmarkStatus(): string {
        return JsonFormat.stringify(VideoCodecBenchmarkService.snapshot())
    }
    function videoCodecBenchmarkPlaybackStart(): bool {
        return VideoCodecBenchmarkService.startPlayback()
    }
    function videoCodecBenchmarkHardwareStart(): bool {
        return VideoCodecBenchmarkService.startHardwareProbe()
    }
    function videoCodecBenchmarkCancel(): bool {
        return VideoCodecBenchmarkService.cancel()
    }
    function videoCodecBenchmarkClear(): bool {
        return VideoCodecBenchmarkService.clear()
    }
    function lifecycleAdaptiveSet(enabled: bool): bool {
        return ConfigService.setSetting("adaptiveLifecycleEnabled", enabled)
    }
    function lifecycleReset(): void {
        SettingsService.resetLifecycleSettings()
    }
    function settingsClose(): void { SettingsService.close() }

    function wallpapersRescan(): void { WallpaperCatalogService.rescan() }
    function wallpapersScan(paths: string): void {
        WallpaperCatalogService.rescan(paths.length > 0 ? paths.split("|") : [])
    }
    function wallpapersStatus(): string {
        return JsonFormat.stringify({
            scanning: WallpaperCatalogService.scanning,
            count: WallpaperCatalogService.wallpapers.length,
            wallpapers: WallpaperCatalogService.wallpapers,
            warnings: WallpaperCatalogService.warnings,
            error: WallpaperCatalogService.error
        })
    }
    function wallpaperProbe(path: string): bool {
        return WallpaperProbeService.enqueue(path)
    }
    function wallpaperProbeStatus(path: string): string {
        return JsonFormat.stringify(WallpaperProbeService.recordFor(path))
    }
    function wallpaperProbeCancel(): void { WallpaperProbeService.cancelAll() }
    function wallpaperProbeCacheStatus(): string {
        return JsonFormat.stringify({
            loaded: WallpaperProbeService.cacheLoaded,
            entries: Object.keys(WallpaperProbeService.cacheEntries).length,
            maximumEntries: WallpaperProbeService.maximumCacheEntries
        })
    }
    function wallpaperPoster(path: string): bool {
        return WallpaperPosterService.request(WallpaperProbeService.recordFor(path))
    }
    function wallpaperPosterStatus(path: string): string {
        return JsonFormat.stringify(WallpaperPosterService.recordFor(path))
    }
    function wallpaperPosterCancel(): void { WallpaperPosterService.cancelAll() }
    function wallpaperChooseDirectory(): void {
        SettingsService.openWallpaperDirectoryPicker()
    }
    function wallpaperOpenOptions(): void {
        SettingsService.openWallpaperOptions()
    }

    function wallpaperSetGlobal(path: string): bool {
        return WallpaperAssignmentService.setGlobal(path)
    }
    function wallpaperClearGlobal(): void { WallpaperAssignmentService.clearGlobal() }
    function wallpaperSetScreen(screen: string, path: string): bool {
        return WallpaperAssignmentService.setForScreen(screen, path)
    }
    function wallpaperClearScreen(screen: string): void {
        WallpaperAssignmentService.clearScreen(screen)
    }
    function wallpaperForScreen(screen: string): string {
        return WallpaperAssignmentService.wallpaperForScreen(screen)
    }
    function wallpaperAssignments(): string {
        return JsonFormat.stringify(WallpaperAssignmentService.snapshot())
    }
    function wallpaperAutomationOverrides(): string {
        return JsonFormat.stringify(
            WallpaperAutomationOverrideService.snapshot())
    }
    function wallpaperAutomationResumeAll(): bool {
        return WallpaperAutomationOverrideService.resumeAll()
    }
    function wallpaperAutomationResumeScreen(screen: string): bool {
        return WallpaperAutomationOverrideService.resumeScreen(screen)
    }
    function wallpaperPlaylists(): string {
        return JsonFormat.stringify(WallpaperPlaylistService.snapshot())
    }
    function wallpaperPlaylistsReplace(document: string): bool {
        return WallpaperPlaylistService.replaceJson(document)
    }
    function wallpaperPlaylistCreate(name: string, mode: string): string {
        return WallpaperPlaylistService.createPlaylist(name, mode)
    }
    function wallpaperPlaylistRemove(id: string): bool {
        return WallpaperPlaylistService.removePlaylist(id)
    }
    function wallpaperPlaylistRename(id: string, name: string): bool {
        return WallpaperPlaylistService.renamePlaylist(id, name)
    }
    function wallpaperPlaylistConfigure(id: string, mode: string,
            seed: int): bool {
        return WallpaperPlaylistService.configurePlaylist(id, mode, seed)
    }
    function wallpaperPlaylistEntryAdd(id: string, path: string,
            durationMs: int): string {
        return WallpaperPlaylistService.addEntry(id, path, durationMs)
    }
    function wallpaperPlaylistEntryRemove(id: string,
            entryId: string): bool {
        return WallpaperPlaylistService.removeEntry(id, entryId)
    }
    function wallpaperPlaylistEntryUpdate(id: string, entryId: string,
            path: string, durationMs: int): bool {
        return WallpaperPlaylistService.updateEntry(
            id, entryId, path, durationMs)
    }
    function wallpaperPlaylistEntryMove(id: string, entryId: string,
            position: int): bool {
        return WallpaperPlaylistService.moveEntry(id, entryId, position)
    }
    function wallpaperPlaylistOrder(id: string): string {
        return JsonFormat.stringify(
            WallpaperPlaylistService.resolvedEntries(id))
    }
    function wallpaperPlaylistSchedulerStatus(): string {
        return JsonFormat.stringify(
            WallpaperPlaylistSchedulerService.snapshot())
    }
    function wallpaperPlaylistApplicationStatus(): string {
        return JsonFormat.stringify(
            WallpaperPlaylistApplicationService.snapshot())
    }
    function wallpaperPlaylistSchedulerRefresh(nowMs: real): bool {
        if (Quickshell.env("QS_TEST_MODE") !== "1")
            return false
        return WallpaperPlaylistSchedulerService.reconcile(nowMs, "ipc-test")
    }
    function wallpaperPlaylistPlan(screen: string, nowMs: real,
            entryId: string, startedAtMs: real): string {
        return JsonFormat.stringify(WallpaperPlaylistSchedulerService.preview(
            screen, nowMs, entryId, startedAtMs))
    }
    function wallpaperPlaylistsClear(): bool {
        return WallpaperPlaylistService.clear()
    }
    function wallpaperPlaylistsValidate(): bool {
        return WallpaperPlaylistService.validate()
    }
    function wallpaperPlaylistTargets(): string {
        return JsonFormat.stringify(WallpaperPlaylistTargetService.snapshot())
    }
    function wallpaperPlaylistForScreen(screen: string): string {
        return WallpaperPlaylistTargetService.playlistForScreen(screen)
    }
    function wallpaperPlaylistSetGlobal(id: string): bool {
        return WallpaperPlaylistTargetService.setGlobal(id)
    }
    function wallpaperPlaylistClearGlobal(): bool {
        return WallpaperPlaylistTargetService.clearGlobal()
    }
    function wallpaperPlaylistSetScreen(screen: string, id: string): bool {
        return WallpaperPlaylistTargetService.setForScreen(screen, id)
    }
    function wallpaperPlaylistClearScreen(screen: string): bool {
        return WallpaperPlaylistTargetService.clearScreen(screen)
    }
    function wallpaperTimeRules(): string {
        return JsonFormat.stringify(WallpaperTimeRuleService.snapshot())
    }
    function wallpaperTimeRulesReplace(document: string): bool {
        return WallpaperTimeRuleService.replaceJson(document)
    }
    function wallpaperTimeRuleCreate(name: string, playlistId: string,
            screen: string, days: string, startMinute: int,
            endMinute: int, priority: int): string {
        return WallpaperTimeRuleService.createRule(name, playlistId,
            screen, days, startMinute, endMinute, priority)
    }
    function wallpaperTimeRuleUpdate(id: string, name: string,
            playlistId: string, screen: string, days: string,
            startMinute: int, endMinute: int, priority: int,
            enabled: bool): bool {
        return WallpaperTimeRuleService.updateRule(id, name, playlistId,
            screen, days, startMinute, endMinute, priority, enabled)
    }
    function wallpaperTimeRuleSetEnabled(id: string,
            enabled: bool): bool {
        return WallpaperTimeRuleService.setEnabled(id, enabled)
    }
    function wallpaperTimeRuleRemove(id: string): bool {
        return WallpaperTimeRuleService.removeRule(id)
    }
    function wallpaperTimeRulesClear(): bool {
        return WallpaperTimeRuleService.clear()
    }
    function wallpaperHooks(): string {
        return JsonFormat.stringify(WallpaperHookService.snapshot())
    }
    function wallpaperHooksReplace(document: string): bool {
        return WallpaperHookService.replaceJson(document)
    }
    function wallpaperHookCreate(name: string, phase: string,
            executable: string, argumentsJson: string, screen: string,
            timeoutMs: int, priority: int): string {
        return WallpaperHookService.createHook(name, phase, executable,
            argumentsJson, screen, timeoutMs, priority)
    }
    function wallpaperHookUpdate(id: string, name: string, phase: string,
            executable: string, argumentsJson: string, screen: string,
            timeoutMs: int, priority: int, enabled: bool): bool {
        return WallpaperHookService.updateHook(id, name, phase, executable,
            argumentsJson, screen, timeoutMs, priority, enabled)
    }
    function wallpaperHookSetEnabled(id: string, enabled: bool): bool {
        return WallpaperHookService.setEnabled(id, enabled)
    }
    function wallpaperHookRemove(id: string): bool {
        return WallpaperHookService.removeHook(id)
    }
    function wallpaperHooksClear(): bool {
        return WallpaperHookService.clear()
    }
    function wallpaperHookExecutorStatus(): string {
        return JsonFormat.stringify(WallpaperHookExecutorService.snapshot())
    }
    function wallpaperHookStatus(): string {
        return JsonFormat.stringify(
            WallpaperHookDiagnosticsService.snapshot())
    }
    function wallpaperHookRunTest(phase: string,
            contextJson: string): string {
        if (Quickshell.env("QS_TEST_MODE") !== "1")
            return ""
        try {
            return WallpaperHookExecutorService.runPhase(
                phase, JSON.parse(contextJson))
        } catch (exception) {
            return ""
        }
    }
    function wallpaperHookCancelTest(runId: string): bool {
        if (Quickshell.env("QS_TEST_MODE") !== "1")
            return false
        return WallpaperHookExecutorService.cancelRun(
            runId, "ipc-test-cancel")
    }
    function wallpaperRenderStatus(): string {
        return JsonFormat.stringify(WallpaperRenderService.snapshot())
    }
    function wallpaperDiagnostics(): string {
        return JsonFormat.stringify(WallpaperDiagnosticsService.snapshot())
    }
    function wallpaperOcclusionStatus(): string {
        return JsonFormat.stringify(WallpaperOcclusionService.snapshot())
    }
    function wallpaperMonitorPowerStatus(): string {
        return JsonFormat.stringify(WallpaperMonitorPowerService.snapshot())
    }
    function wallpaperGuardrails(): string {
        return JsonFormat.stringify(WallpaperGuardrailService.snapshot())
    }
    function wallpaperGuardrailFor(path: string): string {
        return JsonFormat.stringify(WallpaperGuardrailService.assessment(
            "Inspection", path))
    }
    function wallpaperOptimize(target: string, path: string): bool {
        return WallpaperOptimizationService.request(target, path)
    }
    function wallpaperOptimizationSetScale(target: string, path: string,
            multiplier: real): bool {
        return WallpaperOptimizationService.setResolutionScale(
            target, path, multiplier)
    }
    function wallpaperOptimizationScales(target: string, path: string): string {
        return JsonFormat.stringify({
            mode: WallpaperOptimizationService.resolutionMode(),
            selected: WallpaperOptimizationService.selectedResolutionScale(
                target, path),
            maximumCustom:
                WallpaperOptimizationService.maximumResolutionScale(
                    target, path),
            frameRate: {
                mode: WallpaperOptimizationService.frameRateMode(),
                selected: WallpaperOptimizationService.selectedFrameRate(path),
                maximumCustom:
                    WallpaperOptimizationService.sourceFrameRate(path),
                enabled: WallpaperOptimizationService.settingsFrameRateModes()
            },
            bitRateMbps: {
                mode: WallpaperOptimizationService.bitRateMode(),
                selected: WallpaperOptimizationService.selectedBitRate(path),
                maximumCustom:
                    WallpaperOptimizationService.sourceBitRateMbps(path),
                enabled: WallpaperOptimizationService.settingsBitRateModes()
            },
            available: WallpaperOptimizationService.availableResolutionScales(
                target, path),
            candidates: WallpaperOptimizationService.resolutionScales.map(
                multiplier => ({
                    multiplier: multiplier,
                    dimensions: WallpaperOptimizationService.candidateDimensions(
                        target, path, multiplier),
                    available: WallpaperOptimizationService.scaleAvailable(
                        target, path, multiplier)
                }))
        })
    }
    function wallpaperOptimizationStatus(path: string): string {
        return JsonFormat.stringify(WallpaperOptimizationService.recordFor(path))
    }
    function wallpaperOptimizationRecipe(target: string, path: string): string {
        return JsonFormat.stringify(
            WallpaperOptimizationService.recipeSnapshot(target, path))
    }
    function wallpaperOptimizationCancel(): void {
        WallpaperOptimizationService.cancel()
    }
    function wallpaperOptimizationClearCache(): bool {
        return WallpaperOptimizationService.clearCache()
    }
    function wallpaperOptimizationCacheStatus(): string {
        return JsonFormat.stringify(WallpaperOptimizationService.cacheSnapshot())
    }
    function wallpaperCacheScan(): bool {
        return WallpaperCacheService.scan()
    }
    function wallpaperCacheStatus(): string {
        return JsonFormat.stringify(WallpaperCacheService.snapshot())
    }
    function wallpaperCacheCleanupPlan(): string {
        return JsonFormat.stringify(WallpaperCacheService.buildPlan())
    }
    function wallpaperCacheCleanupExecute(): bool {
        return WallpaperCacheService.executeCleanup()
    }
    function monitors(): string {
        const renderers = WallpaperRenderService.snapshot()
        const overrides = WallpaperAssignmentService.screenWallpapers
        return JsonFormat.stringify(Quickshell.screens.map(screen => {
            const name = String(screen.name || "")
            return {
                name: name,
                width: screen.width,
                height: screen.height,
                scale: screen.devicePixelRatio,
                wallpaper: WallpaperAssignmentService.wallpaperForScreen(name),
                wallpaperOverride: Boolean(overrides[name]),
                renderer: renderers[name] || {
                    path: "",
                    state: "unavailable",
                    error: "Renderer is not available"
                }
            }
        }))
    }
}
