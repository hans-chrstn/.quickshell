pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../../core/JsonCopy.js" as JsonCopy
import "WallpaperDraftCopyPlan.js" as CopyPlan
import "WallpaperProjectBundleModel.js" as Bundle

Singleton {
    id: root

    readonly property int maximumQueue: CopyPlan.maximumQueue
    property bool busy: false
    property string operation: "idle"
    property string error: ""
    property real progress: 0
    property double bytesTotal: 0
    property double bytesCopied: 0
    property var queue: []
    property var activeJob: null
    property var jobs: ({})
    property var jobOrder: []
    property int idSequence: 0
    property string processOutput: ""
    property string sourceIdentity: ""
    property string sourceModified: ""
    property bool manifestStarted: false
    property bool cancelRequested: false
    property bool timedOut: false
    property string awaitedWriteToken: ""
    property string pendingFailure: ""

    function publishJob(job) {
        const next = ({})
        for (const id in jobs) next[id] = jobs[id]
        let order = jobOrder.slice()
        if (order.indexOf(job.id) < 0) order.push(job.id)
        next[job.id] = JsonCopy.value(job)
        while (order.length > maximumQueue) delete next[order.shift()]
        jobOrder = order
        jobs = next
    }

    function updateActive(values) {
        if (!activeJob) return
        activeJob = Object.assign({}, activeJob, values || ({}))
        publishJob(activeJob)
    }

    function enqueue(workspaceId, sourcePath, role, assetId) {
        if (queue.length + (activeJob ? 1 : 0) >= maximumQueue) {
            error = "Draft copy queue limit reached"
            return ""
        }
        idSequence += 1
        const id = "copy-" + Date.now().toString(36)
            + "-" + idSequence.toString(36)
        const job = { id: id, workspaceId: String(workspaceId || ""),
            sourcePath: String(sourcePath || ""), role: String(role || ""),
            assetId: String(assetId || ""), state: "queued", phase: "queued",
            progress: 0, bytesTotal: 0, bytesCopied: 0, error: "",
            relativePath: "", destinationPath: "" }
        queue = queue.concat([job])
        publishJob(job)
        error = ""
        startNext()
        return id
    }

    function startNext() {
        if (busy || queue.length === 0
                || WallpaperDraftWorkspaceService.busy) return
        const pending = queue.slice()
        const job = pending.shift()
        queue = pending
        const snapshot = WallpaperDraftWorkspaceService.workspaceSnapshot(
            job.workspaceId)
        if (!snapshot || snapshot.availability?.state !== "ready") {
            publishJob(Object.assign({}, job, { state: "failed", phase: "done",
                error: "Draft workspace is unavailable" }))
            Qt.callLater(startNext)
            return
        }
        const planned = CopyPlan.create(job, snapshot.entry, snapshot.manifest)
        if (!planned.accepted) {
            publishJob(Object.assign({}, job, { state: "failed", phase: "done",
                error: planned.error }))
            Qt.callLater(startNext)
            return
        }
        activeJob = Object.assign({}, job, planned.plan, {
            state: "running", phase: "source-check", progress: 0.05
        })
        busy = true
        operation = "source-check"
        error = ""
        progress = 0.05
        bytesTotal = 0
        bytesCopied = 0
        sourceIdentity = ""
        sourceModified = ""
        manifestStarted = false
        cancelRequested = false
        pendingFailure = ""
        publishJob(activeJob)
        run(["stat", "--printf=%F\n%s\n%y", "--", activeJob.sourcePath])
    }

    function transferTimeout() {
        return Math.min(1800000, Math.max(30000,
            Math.ceil(bytesTotal / 5242880) * 1000 + 30000))
    }

    function run(command, timeoutMs) {
        processOutput = ""
        timedOut = false
        worker.command = command
        worker.running = true
        operationTimeout.interval = Math.max(1000, Number(timeoutMs) || 10000)
        operationTimeout.restart()
    }

    function sourceChecked(exitCode) {
        const lines = processOutput.split("\n")
        const size = Number(lines[1])
        const modified = String(lines[2] || "")
        if (exitCode !== 0 || lines[0] !== "regular file"
                || !Number.isFinite(size) || size < 0) {
            fail("Copy source is missing or is not a regular file")
            return
        }
        bytesTotal = size
        sourceModified = modified
        updateActive({ bytesTotal: size, phase: "space-check", progress: 0.1 })
        operation = "space-check"
        progress = 0.1
        const directory = activeJob.destinationPath.slice(0,
            activeJob.destinationPath.lastIndexOf("/"))
        run(["df", "--output=avail", "-B1", "--", directory])
    }

    function spaceChecked(exitCode) {
        const lines = processOutput.trim().split(/\s+/)
        const available = Number(lines[lines.length - 1])
        const reserve = Math.min(67108864,
            Math.max(1048576, Math.ceil(bytesTotal * 0.05)))
        if (exitCode !== 0 || !Number.isFinite(available)) {
            fail("Destination free space could not be verified")
            return
        }
        if (available < bytesTotal + reserve) {
            fail("Insufficient space in the draft workspace")
            return
        }
        operation = "collision-check"
        progress = 0.15
        updateActive({ phase: operation, progress: progress })
        run(["test", "!", "-e", activeJob.destinationPath])
    }

    function collisionChecked(exitCode) {
        if (exitCode !== 0) {
            fail("Draft destination already exists")
            return
        }
        operation = "temporary-check"
        run(["test", "!", "-e", activeJob.temporaryPath])
    }

    function temporaryChecked(exitCode) {
        if (exitCode !== 0) {
            fail("A partial copy already exists")
            return
        }
        operation = "source-identity"
        progress = 0.2
        updateActive({ phase: operation, progress: progress })
        run(["sha256sum", "--", activeJob.sourcePath], transferTimeout())
    }

    function sourceIdentityReady(exitCode) {
        const identity = processOutput.slice(0, 64)
        if (exitCode !== 0 || !/^[0-9a-f]{64}$/.test(identity)) {
            fail("Copy source identity could not be calculated")
            return
        }
        sourceIdentity = identity
        const snapshot = WallpaperDraftWorkspaceService.workspaceSnapshot(
            activeJob.workspaceId)
        const appended = Bundle.appendFile(snapshot?.manifest, {
            id: activeJob.fileId, assetId: activeJob.assetId,
            role: activeJob.role, relativePath: activeJob.relativePath,
            originalSourcePath: activeJob.sourcePath,
            sizeBytes: 0, identity: "", state: "copying", error: ""
        }, Date.now())
        if (!appended.accepted) {
            fail(appended.error)
            return
        }
        operation = "persisting-copy"
        progress = 0.25
        updateActive({ phase: operation, progress: progress })
        awaitedWriteToken = "copy-start:" + activeJob.id
        if (!WallpaperDraftWorkspaceService.requestManifestWrite(
                activeJob.workspaceId, appended.document, awaitedWriteToken)) {
            fail("Draft manifest is busy")
        } else {
            manifestStarted = true
        }
    }

    function startCopy() {
        operation = "copying"
        progress = 0.35
        updateActive({ phase: operation, progress: progress })
        run(["cp", "--reflink=auto", "--preserve=timestamps", "--",
            activeJob.sourcePath, activeJob.temporaryPath], transferTimeout())
    }

    function copyFinished(exitCode) {
        if (cancelRequested) {
            fail("Copy cancelled")
            return
        }
        if (exitCode !== 0) {
            fail("Source asset could not be copied")
            return
        }
        bytesCopied = bytesTotal
        operation = "source-recheck"
        progress = 0.75
        updateActive({ phase: operation, progress: progress,
            bytesCopied: bytesCopied })
        run(["stat", "--printf=%s\n%y", "--", activeJob.sourcePath])
    }

    function sourceRechecked(exitCode) {
        const lines = processOutput.split("\n")
        if (exitCode !== 0 || Number(lines[0]) !== bytesTotal
                || String(lines[1] || "") !== sourceModified) {
            fail("Copy source changed during import")
            return
        }
        operation = "copy-identity"
        progress = 0.82
        updateActive({ phase: operation, progress: progress })
        run(["sha256sum", "--", activeJob.temporaryPath], transferTimeout())
    }

    function copyIdentityReady(exitCode) {
        const identity = processOutput.slice(0, 64)
        if (exitCode !== 0 || identity !== sourceIdentity) {
            fail("Copied asset failed identity verification")
            return
        }
        if (activeJob.role === "script") {
            operation = "hardening-script"
            progress = 0.88
            updateActive({ phase: operation, progress: progress })
            run(["chmod", "a-x", "--", activeJob.temporaryPath])
        } else {
            publishFile()
        }
    }

    function publishFile() {
        operation = "publishing-file"
        progress = 0.9
        updateActive({ phase: operation, progress: progress })
        run(["mv", "--no-clobber", "--", activeJob.temporaryPath,
            activeJob.destinationPath])
    }

    function filePublished(exitCode) {
        if (exitCode !== 0) {
            fail("Copied asset could not be published")
            return
        }
        operation = "verifying-file"
        progress = 0.94
        updateActive({ phase: operation, progress: progress })
        run(["stat", "--printf=%s", "--", activeJob.destinationPath])
    }

    function fileVerified(exitCode) {
        if (exitCode !== 0 || Number(processOutput) !== bytesTotal) {
            fail("Published asset could not be verified")
            return
        }
        persistTerminal("ready", "")
    }

    function fail(message) {
        pendingFailure = String(message || "Draft copy failed")
        error = pendingFailure
        if (activeJob?.temporaryPath?.length > 0) {
            operation = "cleaning-partial"
            run(["rm", "-f", "--", activeJob.temporaryPath])
        } else {
            persistTerminal("failed", pendingFailure)
        }
    }

    function partialCleaned() {
        persistTerminal("failed", pendingFailure)
    }

    function persistTerminal(state, message) {
        if (!manifestStarted) {
            complete(state, message)
            return
        }
        const snapshot = WallpaperDraftWorkspaceService.workspaceSnapshot(
            activeJob.workspaceId)
        const updated = Bundle.updateFile(snapshot?.manifest, activeJob.fileId, {
            state: state, sizeBytes: state === "ready" ? bytesTotal : 0,
            identity: state === "ready" ? "sha256:" + sourceIdentity : "",
            error: message
        }, Date.now())
        if (!updated.accepted) {
            complete("failed", updated.error)
            return
        }
        operation = "persisting-" + state
        awaitedWriteToken = "copy-" + state + ":" + activeJob.id
        if (!WallpaperDraftWorkspaceService.requestManifestWrite(
                activeJob.workspaceId, updated.document, awaitedWriteToken))
            complete("failed", "Final draft manifest could not be written")
    }

    function complete(state, message) {
        const terminal = state === "ready" ? "ready"
            : cancelRequested ? "cancelled" : "failed"
        progress = terminal === "ready" ? 1 : progress
        updateActive({ state: terminal, phase: "done", progress: progress,
            bytesCopied: bytesCopied, error: String(message || "") })
        busy = false
        operation = "idle"
        error = terminal === "ready" ? "" : String(message || "")
        activeJob = null
        awaitedWriteToken = ""
        pendingFailure = ""
        Qt.callLater(startNext)
    }

    function cancel(jobId) {
        const id = String(jobId || "")
        if (activeJob?.id === id) {
            cancelRequested = true
            if (worker.running) worker.running = false
            else if (awaitedWriteToken.length === 0) fail("Copy cancelled")
            return true
        }
        const index = queue.findIndex(job => job.id === id)
        if (index < 0) return false
        const next = queue.slice()
        const job = next.splice(index, 1)[0]
        queue = next
        publishJob(Object.assign({}, job, { state: "cancelled", phase: "done",
            error: "Copy cancelled" }))
        return true
    }

    function snapshot() {
        return JsonCopy.value({ busy: busy, operation: operation, error: error,
            progress: progress, bytesTotal: bytesTotal,
            bytesCopied: bytesCopied, activeJob: activeJob,
            queued: queue, jobs: jobs })
    }

    Connections {
        target: WallpaperDraftWorkspaceService
        function onBusyChanged() { if (!target.busy) root.startNext() }
        function onManifestWriteFinished(token, accepted, writeError) {
            if (token !== root.awaitedWriteToken || !root.activeJob) return
            root.awaitedWriteToken = ""
            if (!accepted) {
                root.complete("failed", writeError)
            } else if (token.startsWith("copy-start:")) {
                if (root.cancelRequested) root.fail("Copy cancelled")
                else root.startCopy()
            } else if (token.startsWith("copy-ready:")) {
                root.complete("ready", "")
            } else {
                root.complete("failed", root.pendingFailure)
            }
        }
    }

    Timer {
        id: operationTimeout
        repeat: false
        onTriggered: {
            if (!root.busy || !worker.running) return
            root.timedOut = true
            worker.running = false
        }
    }

    Process {
        id: worker
        stdout: StdioCollector { onStreamFinished: root.processOutput = text }
        stderr: StdioCollector {}
        onExited: exitCode => {
            operationTimeout.stop()
            if (root.timedOut && root.operation !== "cleaning-partial") {
                root.timedOut = false
                root.fail("Copy operation timed out")
            } else if (root.cancelRequested
                    && root.operation !== "cleaning-partial") {
                root.fail("Copy cancelled")
            } else if (root.operation === "source-check") root.sourceChecked(exitCode)
            else if (root.operation === "space-check") root.spaceChecked(exitCode)
            else if (root.operation === "collision-check") root.collisionChecked(exitCode)
            else if (root.operation === "temporary-check") root.temporaryChecked(exitCode)
            else if (root.operation === "source-identity") root.sourceIdentityReady(exitCode)
            else if (root.operation === "copying") root.copyFinished(exitCode)
            else if (root.operation === "source-recheck") root.sourceRechecked(exitCode)
            else if (root.operation === "copy-identity") root.copyIdentityReady(exitCode)
            else if (root.operation === "hardening-script") {
                if (exitCode === 0) root.publishFile()
                else root.fail("Imported script permissions could not be restricted")
            }
            else if (root.operation === "publishing-file") root.filePublished(exitCode)
            else if (root.operation === "verifying-file") root.fileVerified(exitCode)
            else if (root.operation === "cleaning-partial") root.partialCleaned()
        }
    }
}
