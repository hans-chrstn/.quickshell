pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../../core/JsonCopy.js" as JsonCopy
import qs.services.jobs
import qs.services.wallpaper
import "WallpaperDraftDerivativePlan.js" as DerivativePlan
import "WallpaperDraftDerivativeCommand.js" as DerivativeCommand
import "WallpaperProjectBundleModel.js" as Bundle

Singleton {
    id: root

    readonly property int maximumQueue: 32
    property bool busy: false
    property string operation: "idle"
    property string error: ""
    property var queue: []
    property var activeJob: null
    property var records: ({})
    property int idSequence: 0
    property string processOutput: ""
    property string outputIdentity: ""
    property double outputSize: 0
    property string writeToken: ""
    property bool manifestStarted: false
    property bool finalPublished: false
    property bool cancelRequested: false
    property string pendingFailure: ""

    function key(workspaceId, assetId, role) {
        return String(workspaceId || "") + "|" + String(assetId || "")
            + "|" + String(role || "")
    }

    function recordFor(workspaceId, assetId, role) {
        return records[key(workspaceId, assetId, role)] || {
            state: "unknown", error: "", outputPath: "", progress: 0
        }
    }

    function publish(job) {
        const next = ({})
        for (const name in records) next[name] = records[name]
        next[key(job.workspaceId, job.assetId, job.role)] = JsonCopy.value(job)
        records = next
    }

    function update(values) {
        if (!activeJob) return
        activeJob = Object.assign({}, activeJob, values || ({}))
        publish(activeJob)
    }

    function request(workspaceId, assetId, role) {
        const requestKey = key(workspaceId, assetId, role)
        if (String(workspaceId || "").length === 0
                || String(assetId || "").length === 0
                || ["thumbnail", "proxy"].indexOf(String(role || "")) < 0)
            return false
        if (activeJob?.requestKey === requestKey
                || queue.some(job => job.requestKey === requestKey))
            return true
        if (queue.length + (activeJob ? 1 : 0) >= maximumQueue) {
            error = "Draft derivative queue limit reached"
            return false
        }
        idSequence += 1
        const job = { id: "derivative-" + Date.now().toString(36) + "-"
                + idSequence.toString(36), requestKey: requestKey,
            workspaceId: String(workspaceId), assetId: String(assetId),
            role: String(role), state: "queued", operation: "queued",
            progress: 0, outputPath: "", error: "" }
        queue = queue.concat([job])
        publish(job)
        error = ""
        startNext()
        return true
    }

    function startNext() {
        if (busy || queue.length === 0
                || WallpaperDraftWorkspaceService.busy
                || !WallpaperMediaTools.posterChecked
                || !BackgroundJobTools.ready) return
        const pending = queue.slice()
        const job = pending.shift()
        queue = pending
        const snapshot = WallpaperDraftWorkspaceService.workspaceSnapshot(
            job.workspaceId)
        const planned = snapshot?.availability?.state === "ready"
            ? DerivativePlan.create(job, snapshot.entry, snapshot.manifest)
            : { accepted: false, error: "Draft workspace is unavailable" }
        if (!planned.accepted) {
            publish(Object.assign({}, job, { state: "failed", operation: "done",
                error: planned.error }))
            Qt.callLater(startNext)
            return
        }
        if (planned.reused) {
            publish(Object.assign({}, job, planned.plan, { state: "ready",
                operation: "done", progress: 1, error: "" }))
            Qt.callLater(startNext)
            return
        }
        activeJob = Object.assign({}, job, planned.plan, {
            state: "running", operation: "checking-output", progress: 0.05
        })
        busy = true
        operation = "checking-output"
        manifestStarted = false
        finalPublished = false
        cancelRequested = false
        pendingFailure = ""
        outputIdentity = ""
        outputSize = 0
        publish(activeJob)
        run(["test", "!", "-e", activeJob.outputPath])
    }

    function run(command, timeoutMs) {
        processOutput = ""
        worker.command = command
        worker.running = true
        timeout.interval = Math.max(1000, Number(timeoutMs) || 10000)
        timeout.restart()
    }

    function outputChecked(exitCode) {
        if (exitCode !== 0) return fail("Derivative destination already exists")
        operation = "checking-partial"
        update({ operation: operation, progress: 0.1 })
        run(["test", "!", "-e", activeJob.temporaryPath])
    }

    function partialChecked(exitCode) {
        if (exitCode !== 0) return fail("A derivative partial already exists")
        const snapshot = WallpaperDraftWorkspaceService.workspaceSnapshot(
            activeJob.workspaceId)
        const appended = Bundle.appendFile(snapshot?.manifest, {
            id: activeJob.fileId, assetId: activeJob.assetId,
            role: activeJob.role, relativePath: activeJob.relativePath,
            originalSourcePath: "", sizeBytes: 0, identity: "",
            state: "copying", error: ""
        }, Date.now())
        if (!appended.accepted) return fail(appended.error)
        manifestStarted = true
        operation = "persisting-start"
        update({ operation: operation, progress: 0.15 })
        writeToken = "derivative-start:" + activeJob.id
        if (!WallpaperDraftWorkspaceService.requestManifestWrite(
                activeJob.workspaceId, appended.document, writeToken))
            fail("Derivative manifest could not be started")
    }

    function generate() {
        const command = DerivativeCommand.create(
            WallpaperMediaTools.ffmpegPath, activeJob)
        if (command.length === 0) return fail("Derivative encoder is unavailable")
        operation = "generating"
        update({ operation: operation, progress: 0.25 })
        run(BackgroundJobTools.wrap(command),
            DerivativeCommand.timeoutFor(activeJob.role))
    }

    function generated(exitCode) {
        if (cancelRequested) return fail("Derivative cancelled")
        if (exitCode !== 0) return fail("Derivative generation failed")
        operation = "verifying-size"
        update({ operation: operation, progress: 0.72 })
        run(["stat", "--printf=%s", "--", activeJob.temporaryPath])
    }

    function sizeVerified(exitCode) {
        outputSize = Number(processOutput)
        if (exitCode !== 0 || !Number.isFinite(outputSize) || outputSize <= 0)
            return fail("Generated derivative is empty")
        operation = "hashing-output"
        update({ operation: operation, progress: 0.8 })
        run(["sha256sum", "--", activeJob.temporaryPath],
            activeJob.role === "thumbnail" ? 10000 : 120000)
    }

    function identityReady(exitCode) {
        const identity = processOutput.slice(0, 64)
        if (exitCode !== 0 || !/^[0-9a-f]{64}$/.test(identity))
            return fail("Derivative identity could not be verified")
        outputIdentity = identity
        operation = "publishing"
        update({ operation: operation, progress: 0.88 })
        run(["mv", "--no-clobber", "--", activeJob.temporaryPath,
            activeJob.outputPath])
    }

    function published(exitCode) {
        if (exitCode !== 0) return fail("Derivative could not be published")
        finalPublished = true
        operation = "verifying-published"
        update({ operation: operation, progress: 0.94 })
        run(["stat", "--printf=%s", "--", activeJob.outputPath])
    }

    function publicationVerified(exitCode) {
        if (exitCode !== 0 || Number(processOutput) !== outputSize)
            return fail("Published derivative could not be verified")
        persistTerminal("ready", "")
    }

    function fail(message) {
        pendingFailure = String(message || "Derivative generation failed")
        error = pendingFailure
        if (activeJob?.temporaryPath?.length > 0 || finalPublished) {
            operation = "cleaning-partial"
            const paths = ["rm", "-f", "--", activeJob.temporaryPath]
            if (finalPublished) paths.push(activeJob.outputPath)
            run(paths)
        } else {
            persistTerminal("failed", pendingFailure)
        }
    }

    function persistTerminal(state, message) {
        if (!manifestStarted) return complete(state, message)
        const snapshot = WallpaperDraftWorkspaceService.workspaceSnapshot(
            activeJob.workspaceId)
        const updated = Bundle.updateFile(snapshot?.manifest, activeJob.fileId, {
            state: state, sizeBytes: state === "ready" ? outputSize : 0,
            identity: state === "ready" ? "sha256:" + outputIdentity : "",
            error: message
        }, Date.now())
        if (!updated.accepted) return complete("failed", updated.error)
        operation = "persisting-" + state
        writeToken = "derivative-" + state + ":" + activeJob.id
        if (!WallpaperDraftWorkspaceService.requestManifestWrite(
                activeJob.workspaceId, updated.document, writeToken))
            complete("failed", "Final derivative manifest could not be written")
    }

    function complete(state, message) {
        const terminal = state === "ready" ? "ready"
            : cancelRequested ? "cancelled" : "failed"
        update({ state: terminal, operation: "done",
            progress: terminal === "ready" ? 1 : activeJob.progress,
            error: String(message || "") })
        busy = false
        operation = "idle"
        error = terminal === "ready" ? "" : String(message || "")
        activeJob = null
        writeToken = ""
        pendingFailure = ""
        Qt.callLater(startNext)
    }

    function cancel(workspaceId, assetId, role) {
        const requestKey = key(workspaceId, assetId, role)
        if (activeJob?.requestKey === requestKey) {
            if (["publishing", "verifying-published", "persisting-ready"]
                    .indexOf(operation) >= 0)
                return true
            cancelRequested = true
            if (worker.running) worker.running = false
            else if (writeToken.length === 0) fail("Derivative cancelled")
            return true
        }
        const index = queue.findIndex(job => job.requestKey === requestKey)
        if (index < 0) return false
        const pending = queue.slice()
        const job = pending.splice(index, 1)[0]
        queue = pending
        publish(Object.assign({}, job, { state: "cancelled",
            operation: "done", error: "Derivative cancelled" }))
        return true
    }

    function snapshot() {
        return JsonCopy.value({ busy: busy, operation: operation,
            error: error, queued: queue, activeJob: activeJob,
            records: records, maximumQueue: maximumQueue })
    }

    Connections {
        target: WallpaperDraftWorkspaceService
        function onBusyChanged() { if (!target.busy) root.startNext() }
        function onManifestWriteFinished(token, accepted, writeError) {
            if (token !== root.writeToken || !root.activeJob) return
            root.writeToken = ""
            if (!accepted) return root.complete("failed", writeError)
            if (token.startsWith("derivative-start:")) {
                if (root.cancelRequested) root.fail("Derivative cancelled")
                else root.generate()
            } else if (token.startsWith("derivative-ready:")) {
                root.complete("ready", "")
            } else {
                root.complete("failed", root.pendingFailure)
            }
        }
    }

    Connections {
        target: WallpaperMediaTools
        function onPosterCheckedChanged() { root.startNext() }
    }
    Connections {
        target: BackgroundJobTools
        function onReadyChanged() { root.startNext() }
    }

    Timer {
        id: timeout
        onTriggered: {
            if (!worker.running || !root.activeJob) return
            worker.running = false
            root.fail("Derivative operation timed out")
        }
    }

    Process {
        id: worker
        stdout: StdioCollector { onStreamFinished: root.processOutput = text }
        onExited: exitCode => {
            timeout.stop()
            if (!root.activeJob) return
            if (root.operation === "checking-output") root.outputChecked(exitCode)
            else if (root.operation === "checking-partial") root.partialChecked(exitCode)
            else if (root.operation === "generating") root.generated(exitCode)
            else if (root.operation === "verifying-size") root.sizeVerified(exitCode)
            else if (root.operation === "hashing-output") root.identityReady(exitCode)
            else if (root.operation === "publishing") root.published(exitCode)
            else if (root.operation === "verifying-published")
                root.publicationVerified(exitCode)
            else if (root.operation === "cleaning-partial")
                root.persistTerminal("failed", root.pendingFailure)
        }
    }
}
