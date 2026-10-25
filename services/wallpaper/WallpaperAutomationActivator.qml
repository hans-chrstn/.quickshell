import QtQuick
import qs.components.lifecycle
import qs.services.wallpaper
import "WallpaperAutomationDemand.js" as AutomationDemand

Item {
    id: root

    readonly property bool ready: WallpaperPlaylistTargetService.loaded
        && WallpaperTimeRuleService.loaded
    readonly property bool requested: AutomationDemand.requested(
        ready,
        WallpaperPlaylistTargetService.globalPlaylistId,
        WallpaperPlaylistTargetService.screenPlaylistIds,
        WallpaperTimeRuleService.rules)

    onRequestedChanged: {
        if (!requested)
            WallpaperScheduledOverlayService.clear()
    }

    LifecycleLoader {
        resourceId: "wallpaper.automation-runtime"
        owner: "shell.wallpaper-automation-activator"
        restorationSource: "Playlist targets and enabled time rules"
        classification: "active-only"
        requestedActive: root.requested
        usageActive: root.requested
        retentionReason: requestedActive ? "automation-demand" : ""
        evictionReason: requestedActive ? "" : root.ready
            ? "no-automation-demand" : "automation-state-loading"
        source: requestedActive
            ? Qt.resolvedUrl("WallpaperAutomationRuntime.qml") : ""
    }
}
