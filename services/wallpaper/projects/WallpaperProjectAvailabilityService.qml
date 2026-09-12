pragma Singleton

import QtQuick
import Quickshell
import "../../../core/JsonCopy.js" as JsonCopy
import qs.services.wallpaper
import qs.services.wallpaper.projects
import "WallpaperProjectAvailability.js" as Availability
import "WallpaperProjectRuntimePlan.js" as RuntimePlan

Singleton {
    id: root

    property bool active: false
    property string activeProjectId: ""
    property var projectDocument: null
    property bool updateScheduled: false
    property var diagnostics: ({
        state: "idle", error: "", projectId: "", complete: true,
        assets: [], enqueuePaths: [], counts: ({
            available: 0, pending: 0, missing: 0, unsupported: 0
        })
    })

    function inspect(projectId) {
        const project = WallpaperProjectService.projectSnapshot(projectId)
        if (!project) {
            diagnostics = Object.assign({}, diagnostics, {
                state: "failed", error: "Project not found: " + projectId,
                projectId: String(projectId || ""), complete: true
            })
            active = false
            return false
        }
        activeProjectId = String(projectId || "")
        projectDocument = project
        active = true
        recompute()
        return true
    }

    function recompute() {
        if (!active || !projectDocument) return
        diagnostics = Availability.plan(
            projectDocument, WallpaperProbeService.records)
        enqueueAvailableWork()
        if (diagnostics.complete) active = false
    }

    function enqueueAvailableWork() {
        const capacity = Math.max(0, WallpaperProbeService.maximumQueueSize
            - WallpaperProbeService.queue.length
            - (WallpaperProbeService.activePath.length > 0 ? 1 : 0))
        for (let index = 0;
                index < diagnostics.enqueuePaths.length && index < capacity;
                ++index)
            WallpaperProbeService.enqueue(diagnostics.enqueuePaths[index])
    }

    function scheduleUpdate() {
        if (!active || updateScheduled) return
        updateScheduled = true
        Qt.callLater(() => {
            root.updateScheduled = false
            root.recompute()
        })
    }

    function suggestedRelink(assetId) {
        const id = String(assetId || "")
        const record = diagnostics.assets.find(asset => asset.assetId === id)
        return record?.relinkSuggested ? String(record.resolvedPath || "") : ""
    }

    function applySuggestedRelink(assetId) {
        const path = suggestedRelink(assetId)
        if (path.length === 0) return false
        const project = WallpaperProjectService.projectSnapshot(activeProjectId)
        const asset = project?.project.assets.find(item => item.id === assetId)
        if (!asset) return false
        const accepted = WallpaperProjectService.relinkAsset(
            activeProjectId, assetId, path, asset.portablePath)
        if (accepted) inspect(activeProjectId)
        return accepted
    }

    function snapshot() {
        return {
            active: active,
            diagnostics: JsonCopy.value(diagnostics)
        }
    }

    function runtimePlan() {
        if (!projectDocument)
            return { accepted: false, error: "No project inspected", plan: null }
        return JsonCopy.value(RuntimePlan.build(projectDocument, diagnostics))
    }

    Connections {
        target: WallpaperProbeService
        function onRecordsChanged() { root.scheduleUpdate() }
        function onQueueChanged() { root.scheduleUpdate() }
        function onActivePathChanged() { root.scheduleUpdate() }
    }
}
