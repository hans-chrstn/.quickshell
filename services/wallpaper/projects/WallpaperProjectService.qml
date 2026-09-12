pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../../../core/Base64.js" as Base64
import "../../../core/JsonCopy.js" as JsonCopy
import qs.services.wallpaper
import "WallpaperProjectLibrary.js" as ProjectLibrary
import "WallpaperProjectModel.js" as ProjectModel
import "WallpaperProjectAssetImport.js" as AssetImport

Singleton {
    id: root

    property bool loaded: false
    property string error: ""
    property string activeProjectId: ""
    property var projects: []
    property int revision: 0
    property int persistedRevision: 0
    property int saveCount: 0
    property int idSequence: 0
    property var lastImportReport: ({
        accepted: false, error: "", imported: [], skipped: []
    })

    readonly property bool dirty: revision !== persistedRevision

    function libraryDocument() {
        return {
            schemaVersion: ProjectLibrary.schemaVersion,
            activeProjectId: activeProjectId,
            projects: projects
        }
    }

    function snapshot() {
        return {
            loaded: loaded,
            dirty: dirty,
            revision: revision,
            persistedRevision: persistedRevision,
            saveCount: saveCount,
            error: error,
            lastImportReport: JsonCopy.value(lastImportReport),
            library: JsonCopy.value(libraryDocument())
        }
    }

    function projectSnapshot(projectId) {
        const index = ProjectLibrary.projectIndex(libraryDocument(), projectId)
        return index < 0 ? null : JsonCopy.value(projects[index])
    }

    function nextId() {
        idSequence += 1
        return "project-" + Date.now().toString(36)
            + "-" + idSequence.toString(36)
    }

    function emptyProject(name) {
        return ProjectModel.normalizeDocument({
            schemaVersion: ProjectModel.schemaVersion,
            project: {
                id: nextId(),
                name: String(name || "").trim() || "Untitled Wallpaper",
                assets: [], tracks: [], markers: [], userProperties: [],
                outputTargets: []
            }
        })
    }

    function applyLibrary(document, markChanged) {
        const parsed = ProjectLibrary.parse(document)
        if (!parsed.accepted) {
            error = parsed.error
            return false
        }
        projects = parsed.document.projects
        activeProjectId = parsed.document.activeProjectId
        error = ""
        if (markChanged) markDirty()
        return true
    }

    function replaceJson(value) {
        if (!loaded) return rejectLoading()
        try {
            return applyLibrary(JSON.parse(String(value || "")), true)
        } catch (exception) {
            error = "Project library JSON is invalid"
            return false
        }
    }

    function createProject(name) {
        if (!loaded) {
            rejectLoading()
            return ""
        }
        const project = emptyProject(name)
        const updated = ProjectLibrary.upsert(libraryDocument(), project)
        if (!updated.accepted) {
            error = updated.error
            return ""
        }
        applyLibrary(updated.document, false)
        activeProjectId = project.project.id
        markDirty()
        return project.project.id
    }

    function upsertJson(value) {
        if (!loaded) return rejectLoading()
        try {
            const updated = ProjectLibrary.upsert(
                libraryDocument(), JSON.parse(String(value || "")))
            if (!updated.accepted) {
                error = updated.error
                return false
            }
            return applyLibrary(updated.document, true)
        } catch (exception) {
            error = "Wallpaper project JSON is invalid"
            return false
        }
    }

    function removeProject(projectId) {
        if (!loaded) return rejectLoading()
        const updated = ProjectLibrary.remove(libraryDocument(), projectId)
        if (!updated.accepted) {
            error = updated.error
            return false
        }
        return applyLibrary(updated.document, true)
    }

    function selectProject(projectId) {
        if (!loaded) return rejectLoading()
        const id = String(projectId || "")
        if (ProjectLibrary.projectIndex(libraryDocument(), id) < 0) {
            error = "Project not found: " + id
            return false
        }
        if (activeProjectId === id) return true
        activeProjectId = id
        error = ""
        markDirty()
        return true
    }

    function relinkAsset(projectId, assetId, sourcePath, portablePath) {
        if (!loaded) return rejectLoading()
        const project = projectSnapshot(projectId)
        if (!project) {
            error = "Project not found: " + String(projectId || "")
            return false
        }
        const relinked = ProjectModel.relinkAsset(
            project, assetId, sourcePath, portablePath)
        if (!relinked.accepted) {
            error = relinked.error
            return false
        }
        const updated = ProjectLibrary.upsert(libraryDocument(), relinked.document)
        return updated.accepted && applyLibrary(updated.document, true)
    }

    function removeAsset(projectId, assetId) {
        if (!loaded) return rejectLoading()
        const project = projectSnapshot(projectId)
        if (!project) {
            error = "Project not found: " + String(projectId || "")
            return false
        }
        const removed = ProjectModel.removeAsset(project, assetId)
        if (!removed.accepted) {
            error = removed.error
            return false
        }
        const updated = ProjectLibrary.upsert(libraryDocument(), removed.document)
        if (!updated.accepted) {
            error = updated.error
            return false
        }
        return applyLibrary(updated.document, true)
    }

    function importAssets(projectId, candidates) {
        if (!loaded) {
            rejectLoading()
            return { accepted: false, error: error,
                imported: [], skipped: [] }
        }
        const project = projectSnapshot(projectId)
        if (!project) {
            error = "Project not found: " + String(projectId || "")
            return { accepted: false, error: error,
                imported: [], skipped: [] }
        }
        const verifiedCandidates = Array.isArray(candidates)
            ? candidates.map(candidate => {
                const path = ProjectModel.normalizedSourcePath(
                    candidate?.sourcePath || candidate?.path)
                return Object.assign({}, candidate, {
                    sourcePath: path,
                    media: WallpaperProbeService.recordFor(path)
                })
            }) : candidates
        const result = AssetImport.apply(project, verifiedCandidates)
        lastImportReport = {
            accepted: result.accepted,
            error: result.error,
            imported: result.imported,
            skipped: result.skipped
        }
        if (!result.accepted) {
            error = result.error
            return JsonCopy.value(lastImportReport)
        }
        const updated = ProjectLibrary.upsert(libraryDocument(), result.document)
        if (!updated.accepted || !applyLibrary(updated.document, true)) {
            lastImportReport = Object.assign({}, lastImportReport, {
                accepted: false,
                error: updated.error || error
            })
        }
        return JsonCopy.value(lastImportReport)
    }

    function importAssetsJson(projectId, value) {
        try {
            let text = String(value || "").trim()
            if (text.startsWith("b64_"))
                text = Base64.decode(text.slice(4))
            else if (text.startsWith("base64:"))
                text = Base64.decode(text.slice(7))
            if (text === null) throw new Error("Invalid Base64")
            return importAssets(projectId, JSON.parse(text))
        } catch (exception) {
            lastImportReport = { accepted: false,
                error: "Import candidate JSON is invalid",
                imported: [], skipped: [] }
            error = lastImportReport.error
            return JsonCopy.value(lastImportReport)
        }
    }

    function rejectLoading() {
        error = "Wallpaper projects are still loading"
        return false
    }

    function markDirty() {
        if (!loaded) return
        revision += 1
        saveTimer.restart()
    }

    function save() {
        adapter.schemaVersion = ProjectLibrary.schemaVersion
        adapter.activeProjectId = activeProjectId
        adapter.projects = JsonCopy.value(projects)
        stateFile.writeAdapter()
        persistedRevision = revision
        saveCount += 1
    }

    Timer {
        id: saveTimer
        interval: 180
        onTriggered: root.save()
    }

    Timer {
        id: reloadTimer
        interval: 260
        onTriggered: stateFile.reload()
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("wallpaper-projects.json")
        watchChanges: true
        printErrors: false
        onFileChanged: reloadTimer.restart()
        onLoaded: {
            root.loaded = true
            try {
                const accepted = root.applyLibrary(JSON.parse(text()), false)
                if (accepted) root.persistedRevision = root.revision
            } catch (exception) {
                root.error = "Wallpaper project library JSON is invalid"
            }
        }
        onLoadFailed: failure => {
            root.loaded = true
            root.error = failure === FileViewError.FileNotFound ? ""
                : "Wallpaper projects could not be loaded"
        }

        JsonAdapter {
            id: adapter
            property int schemaVersion: 1
            property string activeProjectId: ""
            property var projects: []
        }
    }
}
