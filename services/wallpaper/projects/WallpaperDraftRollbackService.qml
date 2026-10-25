pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../../core/JsonCopy.js" as JsonCopy
import "WallpaperProjectBundleModel.js" as Bundle

Singleton {
    id: root

    signal finished(string jobId, bool accepted, string error)

    property bool busy: false
    property string operation: "idle"
    property string error: ""
    property var activeJob: null
    property string writeToken: ""

    function request(job) {
        if (busy || !job || ["ready", "failed", "cancelled"].indexOf(
                String(job.state || "")) < 0) return false
        const snapshot = WallpaperDraftWorkspaceService.workspaceSnapshot(
            job.workspaceId)
        const rootPath = String(snapshot?.entry?.rootPath || "")
        const destination = String(job.destinationPath || "")
        const temporary = String(job.temporaryPath || "")
        if (destination.length === 0) {
            Qt.callLater(() => root.finished(String(job.id || ""), true, ""))
            return true
        }
        if (rootPath.length === 0 || !destination.startsWith(rootPath + "/")
                || !temporary.startsWith(rootPath + "/")) return false
        activeJob = JsonCopy.value(job)
        busy = true
        error = ""
        operation = "removing-files"
        timeout.restart()
        remover.command = ["rm", "-f", "--", destination, temporary]
        remover.running = true
        return true
    }

    function filesRemoved(exitCode) {
        if (exitCode !== 0) {
            complete(false, "Imported draft file could not be removed")
            return
        }
        const snapshot = WallpaperDraftWorkspaceService.workspaceSnapshot(
            activeJob.workspaceId)
        const hasRecord = snapshot?.manifest?.workspace?.files?.some(
            file => file.id === activeJob.fileId) || false
        if (!hasRecord) {
            complete(true, "")
            return
        }
        const removed = Bundle.removeFile(snapshot.manifest,
            activeJob.fileId, Date.now())
        if (!removed.accepted) {
            complete(false, removed.error)
            return
        }
        operation = "persisting-manifest"
        writeToken = "rollback:" + activeJob.id + ":" + Date.now()
        if (!WallpaperDraftWorkspaceService.requestManifestWrite(
                activeJob.workspaceId, removed.document, writeToken))
            complete(false, "Draft rollback could not be persisted")
    }

    function complete(accepted, message) {
        const id = String(activeJob?.id || "")
        busy = false
        operation = "idle"
        error = accepted ? "" : String(message || "Draft rollback failed")
        activeJob = null
        writeToken = ""
        finished(id, accepted, error)
    }

    function snapshot() {
        return JsonCopy.value({ busy: busy, operation: operation,
            error: error, activeJob: activeJob })
    }

    Connections {
        target: WallpaperDraftWorkspaceService
        function onManifestWriteFinished(token, accepted, writeError) {
            if (token !== root.writeToken || !root.activeJob) return
            root.complete(accepted, writeError)
        }
    }

    Timer {
        id: timeout
        interval: 10000
        onTriggered: {
            if (!remover.running) return
            remover.running = false
            root.complete(false, "Draft rollback timed out")
        }
    }

    Process {
        id: remover
        onExited: exitCode => {
            timeout.stop()
            if (root.busy && root.operation === "removing-files")
                root.filesRemoved(exitCode)
        }
    }
}
