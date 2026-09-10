pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../../core/JsonCopy.js" as JsonCopy
import "WallpaperDraftRegistry.js" as Registry
import "WallpaperProjectBundleModel.js" as Bundle

Singleton {
    id: root

    signal manifestWriteFinished(string token, bool accepted, string error)

    readonly property string rootDirectory:
        Quickshell.dataPath("wallpaper-project-drafts")
    property bool loaded: false
    property bool busy: false
    property string operation: "idle"
    property string error: ""
    property var workspaces: []
    property var manifests: ({})
    property var availability: ({})
    property string activeWorkspaceId: ""
    property int idSequence: 0
    property int saveCount: 0
    property var pendingEntry: null
    property var pendingManifest: null
    property var recoveryQueue: []
    property string writePurpose: ""
    property string writeToken: ""
    property string processOutput: ""

    function registryDocument() {
        return { schemaVersion: Registry.schemaVersion,
            workspaces: JsonCopy.value(workspaces) }
    }

    function publishMap(source, key, value) {
        const next = ({})
        for (const name in source) next[name] = source[name]
        if (value === undefined) delete next[key]
        else next[key] = value
        return next
    }

    function entryFor(workspaceId) {
        const id = String(workspaceId || "")
        return workspaces.find(entry => entry.id === id) || null
    }

    function workspaceForProject(projectId) {
        const id = String(projectId || "")
        return workspaces.find(entry => entry.projectId === id) || null
    }

    function workspaceSnapshot(workspaceId) {
        const entry = entryFor(workspaceId)
        if (!entry) return null
        return JsonCopy.value({ entry: entry,
            manifest: manifests[entry.id] || null,
            availability: availability[entry.id] || null })
    }

    function requestManifestWrite(workspaceId, document, token) {
        const entry = entryFor(workspaceId)
        const requestToken = String(token || "")
        if (!loaded || busy || !entry || requestToken.length === 0) return false
        const parsed = Bundle.parse(document)
        if (!parsed.accepted
                || parsed.document.workspace.id !== entry.id
                || parsed.document.workspace.projectId !== entry.projectId)
            return false
        busy = true
        error = ""
        writeToken = requestToken
        writeManifest(entry, parsed.document, "external")
        return true
    }

    function nextWorkspaceId(projectId) {
        idSequence += 1
        return "draft-" + String(projectId || "project").slice(0, 48)
            + "-" + Date.now().toString(36) + "-" + idSequence.toString(36)
    }

    function createDraft(projectId) {
        const id = String(projectId || "")
        if (!loaded || busy) {
            error = !loaded ? "Draft registry is still loading"
                : "Another draft operation is active"
            return ""
        }
        const existing = workspaceForProject(id)
        if (existing) {
            activeWorkspaceId = existing.id
            return existing.id
        }
        if (!WallpaperProjectService.projectSnapshot(id)) {
            error = "Project not found: " + id
            return ""
        }
        const now = Date.now()
        const workspaceId = nextWorkspaceId(id)
        const rootPath = Registry.containedRoot(rootDirectory, workspaceId)
        pendingEntry = {
            id: workspaceId, projectId: id, rootPath: rootPath,
            manifestPath: rootPath + "/bundle.json",
            createdAtMs: now, updatedAtMs: now
        }
        pendingManifest = Bundle.create(workspaceId, id, now)
        busy = true
        operation = "creating-directories"
        error = ""
        filesystemProcess.command = ["mkdir", "-p", "--",
            rootPath + "/media", rootPath + "/audio",
            rootPath + "/scripts", rootPath + "/thumbnails",
            rootPath + "/proxies"]
        filesystemProcess.running = true
        return workspaceId
    }

    function writeManifest(entry, document, purpose) {
        manifestFile.path = entry.manifestPath
        manifestData.schemaVersion = document.schemaVersion
        manifestData.workspace = JsonCopy.value(document.workspace)
        manifestFile.writeAdapter()
        pendingEntry = entry
        pendingManifest = document
        writePurpose = purpose
        operation = purpose === "create" ? "writing-manifest"
            : "recovering-manifest"
        manifestVerifyDelay.restart()
    }

    function verifyManifestWrite() {
        processOutput = ""
        operation = writePurpose === "create" ? "verifying-manifest"
            : "verifying-recovery"
        filesystemProcess.command = ["stat", "--printf=%s", "--",
            pendingEntry.manifestPath]
        filesystemProcess.running = true
    }

    function finishCreate() {
        const updated = Registry.upsert(registryDocument(),
            pendingEntry, rootDirectory)
        if (!updated.accepted) {
            failOperation(updated.error)
            return
        }
        workspaces = updated.document.workspaces
        manifests = publishMap(manifests, pendingEntry.id,
            JsonCopy.value(pendingManifest))
        availability = publishMap(availability, pendingEntry.id, {
            state: "ready", error: ""
        })
        activeWorkspaceId = pendingEntry.id
        scheduleRegistrySave()
        clearOperation()
    }

    function failOperation(message) {
        const externalToken = writePurpose === "external" ? writeToken : ""
        error = String(message || "Draft workspace operation failed")
        if (pendingEntry)
            availability = publishMap(availability, pendingEntry.id, {
                state: "failed", error: error
            })
        clearOperation(false)
        if (externalToken.length > 0)
            manifestWriteFinished(externalToken, false, error)
    }

    function clearOperation(clearError) {
        busy = false
        operation = "idle"
        pendingEntry = null
        pendingManifest = null
        writePurpose = ""
        writeToken = ""
        processOutput = ""
        if (clearError !== false) error = ""
    }

    function scheduleRegistrySave() {
        registryData.schemaVersion = Registry.schemaVersion
        registryData.workspaces = JsonCopy.value(workspaces)
        registrySaveTimer.restart()
    }

    function startRecovery() {
        recoveryQueue = workspaces.slice()
        recoverNext()
    }

    function recoverNext() {
        if (busy || recoveryQueue.length === 0) return
        const queue = recoveryQueue.slice()
        const entry = queue.shift()
        recoveryQueue = queue
        busy = true
        pendingEntry = entry
        operation = "reading-manifest"
        processOutput = ""
        filesystemProcess.command = ["cat", "--", entry.manifestPath]
        filesystemProcess.running = true
    }

    function finishRecoveryRead(exitCode) {
        if (exitCode !== 0) {
            availability = publishMap(availability, pendingEntry.id, {
                state: "missing", error: "Draft manifest is unavailable"
            })
            clearOperation()
            recoverNext()
            return
        }
        try {
            const original = Bundle.parse(JSON.parse(processOutput))
            if (!original.accepted) throw new Error(original.error)
            const recovered = Bundle.recoverInterrupted(
                original.document, Date.now())
            manifests = publishMap(manifests, pendingEntry.id,
                JsonCopy.value(recovered.document))
            availability = publishMap(availability, pendingEntry.id, {
                state: "ready", error: recovered.document.workspace.lastError
            })
            if (JSON.stringify(original.document)
                    !== JSON.stringify(recovered.document)) {
                writeManifest(pendingEntry, recovered.document, "recover")
                return
            }
            clearOperation()
            recoverNext()
        } catch (exception) {
            availability = publishMap(availability, pendingEntry.id, {
                state: "corrupt", error: "Draft manifest is invalid"
            })
            clearOperation()
            recoverNext()
        }
    }

    function discardDraft(workspaceId, confirmation) {
        const entry = entryFor(workspaceId)
        if (!loaded || busy || !entry
                || confirmation !== "discard:" + entry.id) {
            error = !entry ? "Draft workspace not found"
                : "Draft discard confirmation does not match"
            return false
        }
        const expected = Registry.containedRoot(rootDirectory, entry.id)
        if (entry.rootPath !== expected || expected === rootDirectory
                || !expected.startsWith(rootDirectory + "/")) {
            error = "Draft path failed containment validation"
            return false
        }
        busy = true
        operation = "discarding"
        pendingEntry = entry
        filesystemProcess.command = ["rm", "-rf", "--", expected]
        filesystemProcess.running = true
        return true
    }

    function finishDiscard(exitCode) {
        if (exitCode !== 0) {
            failOperation("Draft workspace could not be removed")
            return
        }
        const id = pendingEntry.id
        const updated = Registry.remove(registryDocument(), id, rootDirectory)
        workspaces = updated.document.workspaces
        manifests = publishMap(manifests, id, undefined)
        availability = publishMap(availability, id, undefined)
        if (activeWorkspaceId === id) activeWorkspaceId = ""
        scheduleRegistrySave()
        clearOperation()
    }

    function finishExternalWrite() {
        const token = writeToken
        const workspaceId = pendingEntry.id
        manifests = publishMap(manifests, workspaceId,
            JsonCopy.value(pendingManifest))
        availability = publishMap(availability, workspaceId, {
            state: "ready", error: pendingManifest.workspace.lastError
        })
        clearOperation()
        manifestWriteFinished(token, true, "")
    }

    function snapshot() {
        return JsonCopy.value({
            loaded: loaded, busy: busy, operation: operation, error: error,
            rootDirectory: rootDirectory,
            activeWorkspaceId: activeWorkspaceId,
            workspaces: workspaces,
            availability: availability,
            manifests: manifests,
            recoveryPending: recoveryQueue.length,
            saveCount: saveCount
        })
    }

    Timer {
        id: registrySaveTimer
        interval: 180
        onTriggered: {
            registryFile.writeAdapter()
            root.saveCount += 1
        }
    }

    Timer {
        id: manifestVerifyDelay
        interval: 60
        onTriggered: root.verifyManifestWrite()
    }

    Process {
        id: filesystemProcess
        stdout: StdioCollector {
            onStreamFinished: root.processOutput = text
        }
        onExited: exitCode => {
            if (root.operation === "creating-directories") {
                if (exitCode !== 0) root.failOperation(
                    "Draft directories could not be created")
                else root.writeManifest(root.pendingEntry,
                    root.pendingManifest, "create")
            } else if (root.operation === "verifying-manifest"
                    || root.operation === "verifying-recovery") {
                if (exitCode !== 0 || Number(root.processOutput) <= 0) {
                    root.failOperation("Draft manifest could not be verified")
                } else if (root.writePurpose === "create") {
                    root.finishCreate()
                } else if (root.writePurpose === "external") {
                    root.finishExternalWrite()
                } else {
                    root.clearOperation()
                    root.recoverNext()
                }
            } else if (root.operation === "reading-manifest") {
                root.finishRecoveryRead(exitCode)
            } else if (root.operation === "discarding") {
                root.finishDiscard(exitCode)
            }
        }
    }

    FileView {
        id: manifestFile
        path: ""
        printErrors: false
        JsonAdapter {
            id: manifestData
            property int schemaVersion: 1
            property var workspace: ({})
        }
    }

    FileView {
        id: registryFile
        path: Quickshell.statePath("wallpaper-project-drafts.json")
        watchChanges: true
        printErrors: false
        onLoaded: {
            try {
                const parsed = Registry.parse(JSON.parse(text()),
                    root.rootDirectory)
                if (!parsed.accepted) throw new Error(parsed.error)
                root.workspaces = parsed.document.workspaces
                root.error = ""
            } catch (exception) {
                root.error = "Draft registry is invalid"
            }
            root.loaded = true
            root.startRecovery()
        }
        onLoadFailed: failure => {
            root.loaded = true
            root.error = failure === FileViewError.FileNotFound ? ""
                : "Draft registry could not be loaded"
            root.startRecovery()
        }
        JsonAdapter {
            id: registryData
            property int schemaVersion: 1
            property var workspaces: []
        }
    }
}
