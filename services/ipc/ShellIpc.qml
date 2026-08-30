import QtQuick
import Quickshell
import Quickshell.Io
import qs.services.config
import qs.services.launcher
import qs.services.lifecycle
import qs.services.power
import qs.services.session
import qs.services.settings
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
    function settingsBack(): bool { return SettingsService.back() }
    function settingsSet(key: string, value: string): bool {
        return ConfigService.setSetting(key, value)
    }
    function configStatus(): string {
        return JsonFormat.stringify(ConfigService.snapshot())
    }
    function lifecycleStatus(): string {
        return JsonFormat.stringify(LifecycleService.snapshot())
    }
    function lifecycleAdaptiveSet(enabled: bool): bool {
        return ConfigService.setSetting("adaptiveLifecycleEnabled", enabled)
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
            selected: WallpaperOptimizationService.selectedResolutionScale(
                target, path),
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
