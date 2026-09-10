pragma Singleton

import QtQuick
import Quickshell
import "../../../core/JsonCopy.js" as JsonCopy
import qs.services.wallpaper
import "WallpaperProjectAssetImport.js" as AssetImport
import "WallpaperDraftEmbeddedReuse.js" as EmbeddedReuse

Singleton {
    id: root

    signal finished(var report)

    property bool busy: false
    property string phase: "idle"
    property var report: ({ accepted: false, error: "",
        imported: [], skipped: [] })
    property string projectId: ""
    property int startingRevision: 0
    property var pendingPaths: []
    property var candidates: []
    property var skipped: []
    property string workspaceId: ""
    property bool workspaceCreated: false
    property var jobIds: []
    property var candidatesByJob: ({})
    property var reusedCandidates: []
    property var rollbackQueue: []
    property var rollbackReport: null
    property bool cancelled: false
    property bool updateScheduled: false

    function clearReport() {
        if (busy) return false
        report = { accepted: false, error: "", imported: [], skipped: [] }
        return true
    }

    function reject(message) {
        if (busy) return false
        report = { accepted: false, error: String(message || "Import rejected"),
            imported: [], skipped: [] }
        return false
    }

    function request(requestedProjectId, paths) {
        if (busy || !Array.isArray(paths)) return false
        const unique = []
        for (const value of paths) {
            const path = String(value || "")
            if (path.length > 0 && unique.indexOf(path) < 0) unique.push(path)
        }
        if (unique.length === 0 || unique.length > 64) {
            report = { accepted: false,
                error: unique.length > 64 ? "Import batch limit exceeded"
                    : "Select at least one file", imported: [], skipped: [] }
            return false
        }
        const project = WallpaperProjectService.projectSnapshot(
            requestedProjectId)
        if (!project) {
            report = { accepted: false, error: "Wallpaper project is unavailable",
                imported: [], skipped: [] }
            return false
        }
        busy = true
        phase = "probing-sources"
        report = { accepted: false, error: "Inspecting selected media",
            imported: [], skipped: [] }
        projectId = String(requestedProjectId || "")
        startingRevision = WallpaperProjectService.revision
        pendingPaths = unique
        candidates = []
        skipped = []
        workspaceId = ""
        workspaceCreated = false
        jobIds = []
        candidatesByJob = ({})
        reusedCandidates = []
        rollbackQueue = []
        rollbackReport = null
        cancelled = false
        for (const path of unique) WallpaperProbeService.enqueue(path)
        scheduleUpdate()
        return true
    }

    function scheduleUpdate() {
        if (!busy || updateScheduled) return
        updateScheduled = true
        Qt.callLater(() => {
            root.updateScheduled = false
            root.advance()
        })
    }

    function terminalProbe(state) {
        return ["unknown", "queued", "probing"].indexOf(state) < 0
    }

    function prepareCandidates() {
        for (const path of pendingPaths)
            if (!terminalProbe(WallpaperProbeService.recordFor(path).state))
                return
        if (cancelled) {
            finishCancelled()
            return
        }
        const project = WallpaperProjectService.projectSnapshot(projectId)
        const requested = pendingPaths.map(path => ({ sourcePath: path,
            media: WallpaperProbeService.recordFor(path) }))
        const planned = AssetImport.apply(project, requested)
        skipped = JsonCopy.value(planned.skipped || [])
        if (!planned.accepted || planned.imported.length === 0) {
            finish({ accepted: false, error: planned.error,
                imported: [], skipped: skipped })
            return
        }
        candidates = planned.imported.map(asset => ({
            assetId: asset.id, name: asset.name,
            sourcePath: asset.sourcePath
        }))
        ensureWorkspace()
    }

    function ensureWorkspace() {
        phase = "preparing-workspace"
        const existing = WallpaperDraftWorkspaceService.workspaceForProject(
            projectId)
        if (existing) {
            workspaceId = existing.id
            workspaceCreated = false
            scheduleUpdate()
            return
        }
        workspaceCreated = true
        workspaceId = WallpaperDraftWorkspaceService.createDraft(projectId)
        if (workspaceId.length === 0 && !WallpaperDraftWorkspaceService.busy) {
            fail(WallpaperDraftWorkspaceService.error
                || "Draft workspace could not be created")
        }
    }

    function workspaceReady() {
        if (workspaceId.length === 0) return false
        const snapshot = WallpaperDraftWorkspaceService.workspaceSnapshot(
            workspaceId)
        return snapshot?.availability?.state === "ready"
            && !WallpaperDraftWorkspaceService.busy
    }

    function beginCopies() {
        if (cancelled) {
            beginRollback()
            return
        }
        const ids = []
        const byJob = ({})
        const reused = []
        const snapshot = WallpaperDraftWorkspaceService.workspaceSnapshot(
            workspaceId)
        const project = WallpaperProjectService.projectSnapshot(projectId)
        for (const candidate of candidates) {
            const reusable = EmbeddedReuse.resolve(candidate, snapshot?.entry,
                snapshot?.manifest, project)
            if (reusable.found) {
                if (reusable.accepted) {
                    reused.push(reusable.asset)
                    WallpaperProbeService.enqueue(reusable.asset.sourcePath)
                } else {
                    skipped.push({ path: candidate.sourcePath,
                        reason: "reuse-rejected", error: reusable.error })
                }
                continue
            }
            const jobId = WallpaperDraftCopyService.enqueue(workspaceId,
                candidate.sourcePath, "media", candidate.assetId)
            if (jobId.length === 0) {
                skipped.push({ path: candidate.sourcePath,
                    reason: "copy-rejected",
                    error: WallpaperDraftCopyService.error })
                continue
            }
            ids.push(jobId)
            byJob[jobId] = candidate
        }
        jobIds = ids
        candidatesByJob = byJob
        reusedCandidates = reused
        phase = "copying-assets"
        report = { accepted: false, error: "Embedding selected media",
            imported: [], skipped: JsonCopy.value(skipped) }
        if (ids.length === 0 && reused.length > 0) {
            candidates = reused
            phase = "probing-embedded"
            report = { accepted: false, error: "Verifying embedded media",
                imported: [], skipped: JsonCopy.value(skipped) }
            scheduleUpdate()
        } else if (ids.length === 0) fail("No selected media could be embedded")
        else scheduleUpdate()
    }

    function copyTerminal(state) {
        return ["ready", "failed", "cancelled", "rolled-back",
            "rollback-failed"].indexOf(state) >= 0
    }

    function evaluateCopies() {
        const jobs = WallpaperDraftCopyService.jobs
        for (const id of jobIds)
            if (!jobs[id] || !copyTerminal(jobs[id].state)) return
        if (cancelled) {
            beginRollback()
            return
        }
        const embedded = reusedCandidates.slice()
        for (const id of jobIds) {
            const job = jobs[id]
            const candidate = candidatesByJob[id]
            if (job.state === "ready") {
                embedded.push({ assetId: candidate.assetId,
                    name: candidate.name, sourcePath: job.destinationPath,
                    portablePath: job.relativePath })
                WallpaperProbeService.enqueue(job.destinationPath)
            } else {
                skipped.push({ path: candidate.sourcePath,
                    reason: job.state === "cancelled" ? "cancelled" : "copy-failed",
                    error: job.error })
            }
        }
        candidates = embedded
        if (embedded.length === 0) {
            fail("No selected media was embedded")
            return
        }
        phase = "probing-embedded"
        report = { accepted: false, error: "Verifying embedded media",
            imported: [], skipped: JsonCopy.value(skipped) }
        scheduleUpdate()
    }

    function commitEmbedded() {
        for (const candidate of candidates)
            if (!terminalProbe(WallpaperProbeService.recordFor(
                    candidate.sourcePath).state)) return
        if (cancelled) {
            beginRollback()
            return
        }
        if (WallpaperProjectService.revision !== startingRevision) {
            fail("Project changed during import; embedded files remain in the draft")
            return
        }
        phase = "committing-project"
        const result = WallpaperProjectService.importAssets(projectId, candidates)
        const combined = (result.skipped || []).concat(skipped)
        finish({ accepted: result.imported?.length > 0,
            error: result.imported?.length > 0 ? "" : result.error,
            imported: result.imported || [], skipped: combined })
    }

    function cancel() {
        if (!busy) return false
        cancelled = true
        rollbackReport = cancelledReport()
        if (jobIds.length === 0) {
            if (workspaceCreated) {
                phase = "awaiting-workspace-cancel"
                scheduleUpdate()
            } else {
                finishCancelled()
            }
            return true
        }
        phase = "cancelling"
        for (const id of jobIds) WallpaperDraftCopyService.cancel(id)
        scheduleUpdate()
        return true
    }

    function beginRollback(finalReport) {
        phase = "rolling-back"
        rollbackReport = JsonCopy.value(finalReport || rollbackReport
            || cancelledReport())
        rollbackQueue = jobIds.slice()
        continueRollback()
    }

    function continueRollback() {
        if (WallpaperDraftCopyService.busy
                || WallpaperDraftRollbackService.busy) return
        const pending = rollbackQueue.slice()
        if (pending.length === 0) {
            if (workspaceCreated && workspaceId.length > 0) {
                phase = "discarding-new-workspace"
                if (!WallpaperDraftWorkspaceService.entryFor(workspaceId)) {
                    finish(rollbackReport)
                } else if (!WallpaperDraftWorkspaceService.discardDraft(
                        workspaceId, "discard:" + workspaceId)) {
                    finish({ accepted: false,
                        error: "New draft workspace could not be discarded",
                        imported: [], skipped: JsonCopy.value(skipped) })
                }
            } else {
                finish(rollbackReport)
            }
            return
        }
        const id = pending.shift()
        rollbackQueue = pending
        if (!WallpaperDraftRollbackService.request(
                WallpaperDraftCopyService.jobs[id])) {
            fail("Imported draft files could not be rolled back")
        }
    }

    function finishCancelled() {
        finish(cancelledReport())
    }

    function cancelledReport() {
        return { accepted: false, error: "Import cancelled",
            imported: [], skipped: pendingPaths.map(path => ({ path: path,
                reason: "cancelled", error: "Import cancelled" })) }
    }

    function fail(message) {
        const value = { accepted: false,
            error: String(message || "Import failed"), imported: [],
            skipped: JsonCopy.value(skipped) }
        if (phase === "rolling-back") {
            finish(value)
        } else if (jobIds.length > 0
                && phase !== "discarding-new-workspace") {
            for (const id of jobIds) WallpaperDraftCopyService.cancel(id)
            beginRollback(value)
        } else if (workspaceCreated && workspaceId.length > 0
                && phase !== "discarding-new-workspace") {
            beginRollback(value)
        } else {
            finish(value)
        }
    }

    function finish(value) {
        report = JsonCopy.value(value)
        busy = false
        phase = "idle"
        const result = JsonCopy.value(report)
        projectId = ""
        pendingPaths = []
        candidates = []
        jobIds = []
        candidatesByJob = ({})
        rollbackQueue = []
        rollbackReport = null
        cancelled = false
        finished(result)
    }

    function advance() {
        if (!busy) return
        if (phase === "probing-sources") prepareCandidates()
        else if (phase === "preparing-workspace") {
            if (cancelled && workspaceId.length === 0
                    && !WallpaperDraftWorkspaceService.busy) finishCancelled()
            else if (workspaceReady()) beginCopies()
        } else if (phase === "copying-assets" || phase === "cancelling") {
            evaluateCopies()
        } else if (phase === "probing-embedded") commitEmbedded()
        else if (phase === "rolling-back") continueRollback()
        else if (phase === "awaiting-workspace-cancel"
                && !WallpaperDraftWorkspaceService.busy) {
            if (workspaceId.length > 0
                    && WallpaperDraftWorkspaceService.entryFor(workspaceId)) {
                phase = "discarding-new-workspace"
                if (!WallpaperDraftWorkspaceService.discardDraft(workspaceId,
                        "discard:" + workspaceId)) finish(rollbackReport)
            } else {
                finish(rollbackReport)
            }
        }
        else if (phase === "discarding-new-workspace"
                && !WallpaperDraftWorkspaceService.busy
                && !WallpaperDraftWorkspaceService.entryFor(workspaceId))
            finish(rollbackReport)
    }

    Connections {
        target: WallpaperProbeService
        function onRecordsChanged() { root.scheduleUpdate() }
        function onQueueChanged() { root.scheduleUpdate() }
        function onActivePathChanged() { root.scheduleUpdate() }
    }

    Connections {
        target: WallpaperDraftWorkspaceService
        function onBusyChanged() { root.scheduleUpdate() }
        function onAvailabilityChanged() { root.scheduleUpdate() }
    }

    Connections {
        target: WallpaperDraftCopyService
        function onJobsChanged() { root.scheduleUpdate() }
        function onBusyChanged() { root.scheduleUpdate() }
    }

    Connections {
        target: WallpaperDraftRollbackService
        function onBusyChanged() { root.scheduleUpdate() }
        function onFinished(jobId, accepted, rollbackError) {
            if (!root.busy || root.phase !== "rolling-back") return
            if (!accepted) {
                root.finish({ accepted: false,
                    error: rollbackError || "Draft rollback failed",
                    imported: [], skipped: JsonCopy.value(root.skipped) })
            } else {
                root.scheduleUpdate()
            }
        }
    }
}
