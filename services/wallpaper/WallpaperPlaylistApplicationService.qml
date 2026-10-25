pragma Singleton

import QtQuick
import Quickshell
import "WallpaperPlaylistApplication.js" as Application

Singleton {
    id: root

    readonly property var paths: WallpaperScheduledOverlayService.paths
    property bool reconcileScheduled: false
    property double lastAppliedAtMs: 0
    property string lastReason: ""
    property var pendingPaths: null
    property var pendingChanges: []
    property string pendingReason: ""
    property string hookStage: ""
    property string hookRunId: ""
    property bool reconcileQueued: false
    property string queuedReason: ""
    property bool staleBeforeApply: false
    readonly property int maximumScreens: Application.maximumScreens
    readonly property bool active: Object.keys(paths).length > 0

    function pathForScreen(screenName) {
        return String(paths[String(screenName || "").trim()] || "")
    }

    function samePaths(first, second) {
        const firstKeys = Object.keys(first)
        const secondKeys = Object.keys(second)
        if (firstKeys.length !== secondKeys.length)
            return false
        for (const name of firstKeys) {
            if (first[name] !== second[name])
                return false
        }
        return true
    }

    function reconcile(reason) {
        reconcileScheduled = false
        if (WallpaperPlaylistSchedulerService.applicationSuppressed)
            return false
        const updated = Application.pathsForPlans(
            WallpaperPlaylistSchedulerService.plans, maximumScreens)
        for (const screenName in updated) {
            if (WallpaperAutomationOverrideService
                    .suppressedForScreen(screenName))
                delete updated[screenName]
        }
        if (hookStage.length > 0) {
            if (samePaths(pendingPaths || ({}), updated))
                return false
            reconcileQueued = true
            queuedReason = String(reason || "scheduler-state")
                .trim().slice(0, 64)
            if (hookStage === "pre-change")
                staleBeforeApply = true
            if (hookRunId.length > 0)
                WallpaperHookExecutorService.cancelRun(
                    hookRunId, "superseded-" + hookStage)
            return false
        }
        if (samePaths(paths, updated))
            return false
        beginHookedApplication(updated, reason)
        return true
    }

    function transitionContext(screenName, nextPath) {
        const plan = WallpaperPlaylistSchedulerService.plans[screenName]
            || ({})
        const previousPath = pathForScreen(screenName)
            || WallpaperAssignmentService.wallpaperForScreen(screenName)
        const effectiveNext = String(nextPath || "")
            || WallpaperAssignmentService.wallpaperForScreen(screenName)
        return {
            screen: screenName,
            path: effectiveNext,
            previousPath: previousPath,
            source: String(plan.selectionSource || (nextPath
                ? "playlist" : "manual-fallback")),
            playlistId: String(plan.playlistId || ""),
            ruleId: String(plan.ruleId || ""),
            entryId: String(plan.entryId || ""),
            reason: pendingReason
        }
    }

    function changedOutputs(updated) {
        const names = Array.from(new Set(
            Object.keys(paths).concat(Object.keys(updated)))).sort()
        const result = []
        for (const name of names) {
            const previous = String(paths[name] || "")
            const next = String(updated[name] || "")
            if (previous !== next)
                result.push({
                    screen: name,
                    path: next,
                    context: transitionContext(name, next)
                })
        }
        return result
    }

    function hookRequests(phase) {
        return pendingChanges.map(change => ({
            phase: phase,
            context: change.context
        }))
    }

    function beginHookedApplication(updated, reason) {
        pendingPaths = Object.assign({}, updated)
        pendingReason = String(reason || "scheduler-state")
            .trim().slice(0, 64)
        pendingChanges = changedOutputs(updated)
        hookStage = "pre-change"
        hookRunId = WallpaperHookExecutorService.runRequests(
            hookRequests(hookStage))
        if (hookRunId.length === 0)
            applyPendingPaths()
    }

    function applyPendingPaths() {
        WallpaperScheduledOverlayService.replace(pendingPaths)
        lastAppliedAtMs = Date.now()
        lastReason = pendingReason
        hookStage = "post-change"
        hookRunId = WallpaperHookExecutorService.runRequests(
            hookRequests(hookStage))
        if (hookRunId.length === 0)
            finishHookedApplication()
    }

    function finishHookedApplication() {
        pendingPaths = null
        pendingChanges = []
        pendingReason = ""
        hookStage = ""
        hookRunId = ""
        staleBeforeApply = false
        if (reconcileQueued) {
            reconcileQueued = false
            const reason = queuedReason || "queued-scheduler-state"
            queuedReason = ""
            scheduleReconcile(reason)
        }
    }

    function scheduleReconcile(reason) {
        if (reconcileScheduled)
            return
        reconcileScheduled = true
        Qt.callLater(function() { root.reconcile(reason) })
    }

    function snapshot() {
        return {
            active: active,
            suppressed:
                WallpaperPlaylistSchedulerService.applicationSuppressed,
            suppressedReason: WallpaperPlaylistSchedulerService
                .applicationSuppressedReason,
            paths: Object.assign({}, paths),
            lastAppliedAtMs: lastAppliedAtMs,
            lastReason: lastReason,
            hookStage: hookStage,
            hookRunId: hookRunId,
            hookChangeCount: pendingChanges.length,
            reconcileQueued: reconcileQueued,
            queuedReason: queuedReason,
            staleBeforeApply: staleBeforeApply
        }
    }

    Connections {
        target: WallpaperHookExecutorService
        function onRunFinished(runId) {
            if (runId !== root.hookRunId)
                return
            root.hookRunId = ""
            if (root.hookStage === "pre-change") {
                if (root.staleBeforeApply)
                    root.finishHookedApplication()
                else
                    root.applyPendingPaths()
            }
            else if (root.hookStage === "post-change")
                root.finishHookedApplication()
        }
    }

    Connections {
        target: WallpaperPlaylistSchedulerService
        function onPlansChanged() {
            root.scheduleReconcile("scheduler-plans")
        }
        function onApplicationSuppressedChanged() {
            if (!WallpaperPlaylistSchedulerService.applicationSuppressed)
                root.scheduleReconcile("suppression-ended")
        }
    }

    Connections {
        target: WallpaperAutomationOverrideService
        function onGlobalSuppressedChanged() {
            root.scheduleReconcile("global-manual-override")
        }
        function onScreenSuppressionsChanged() {
            root.scheduleReconcile("screen-manual-override")
        }
    }
}
