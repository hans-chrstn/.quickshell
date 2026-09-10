pragma Singleton

import QtQuick
import Quickshell
import "../../../core/JsonCopy.js" as JsonCopy
import "WallpaperDraftSavePlan.js" as SavePlan
import qs.core
import qs.services
import qs.services.notifications
import qs.services.wallpaper

Singleton {
    id: root

    property bool opened: false
    property bool closing: false
    property string targetScreenName: ""
    property string selectedAssetId: ""
    property bool pickerOpened: false
    property bool saveAsOpened: false
    property bool saveAsChoosingParent: false
    property string saveParentPath: ""
    property string saveFolderName: ""
    readonly property bool importBusy: WallpaperEditorImportService.busy
    readonly property var importReport: WallpaperEditorImportService.report
    readonly property var activeProject: {
        const revision = WallpaperProjectService.revision
        const id = WallpaperProjectService.activeProjectId
        return id.length > 0
            ? WallpaperProjectService.projectSnapshot(id) : null
    }
    readonly property string projectName:
        activeProject?.project?.name || "Untitled Wallpaper"
    readonly property string workspaceId: {
        const projectId = activeProject?.project?.id || ""
        return projectId.length > 0
            ? (WallpaperDraftWorkspaceService.workspaceForProject(projectId)?.id
                || "") : ""
    }
    readonly property var mediaItems: {
        const project = activeProject?.project
        const diagnostics = WallpaperProjectAvailabilityService.diagnostics
        if (!project) return []
        const byId = ({})
        if (diagnostics.projectId === project.id) {
            for (const record of diagnostics.assets || [])
                byId[record.assetId] = record
        }
        return project.assets.map(asset => {
            const resolved = byId[asset.id] || ({ state: "pending" })
            return {
                id: asset.id,
                name: asset.name,
                declaredKind: asset.kind,
                sourcePath: asset.sourcePath,
                portablePath: asset.portablePath,
                state: String(resolved.state || "pending"),
                resolvedPath: String(resolved.resolvedPath || ""),
                media: resolved.media || null,
                error: String(resolved.error || "")
            }
        })
    }
    readonly property var selectedAsset: mediaItems.find(
        asset => asset.id === selectedAssetId) || null
    readonly property bool saveFolderNameValid:
        SavePlan.folderName(saveFolderName).length > 0
    readonly property var savePreview: {
        const workspaceRevision = WallpaperDraftWorkspaceService.manifests
        const registryRevision = WallpaperDraftWorkspaceService.workspaces
        if (!saveAsOpened || workspaceId.length === 0)
            return { accepted: false, error: "Draft workspace is unavailable",
                plan: null }
        const snapshot = WallpaperDraftWorkspaceService.workspaceSnapshot(
            workspaceId)
        return SavePlan.create({
            parentPath: saveParentPath,
            folderName: saveFolderName,
            operationId: "preview"
        }, snapshot?.entry, snapshot?.manifest, 0)
    }

    function inspectActiveProject() {
        const id = activeProject?.project?.id || ""
        if (id.length > 0)
            WallpaperProjectAvailabilityService.inspect(id)
    }

    function reconcileSelection() {
        if (selectedAssetId.length > 0
                && mediaItems.some(asset => asset.id === selectedAssetId))
            return
        selectedAssetId = mediaItems.length > 0 ? mediaItems[0].id : ""
    }

    function selectAsset(assetId) {
        const id = String(assetId || "")
        if (!mediaItems.some(asset => asset.id === id)) return false
        selectedAssetId = id
        return true
    }

    function removeSelectedAsset() {
        const projectId = activeProject?.project?.id || ""
        const assetId = selectedAssetId
        if (projectId.length === 0 || assetId.length === 0 || importBusy)
            return false
        const removed = WallpaperProjectService.removeAsset(projectId, assetId)
        if (removed) {
            selectedAssetId = ""
            inspectActiveProject()
            reconcileSelection()
        }
        return removed
    }

    function openPicker() {
        if (importBusy) return false
        if (!activeProject) {
            const projectId = WallpaperProjectService.createProject(
                "Untitled Wallpaper")
            if (projectId.length === 0)
                return WallpaperEditorImportService.reject(
                    WallpaperProjectService.error
                        || "A wallpaper project could not be created")
        }
        WallpaperEditorImportService.clearReport()
        pickerOpened = true
        return true
    }

    function cancelPicker() {
        pickerOpened = false
        WallpaperEditorImportService.cancel()
    }

    function requestImport(paths) {
        const projectId = activeProject?.project?.id || ""
        return pickerOpened && WallpaperEditorImportService.request(projectId, paths)
    }

    function openSaveAs() {
        if (!activeProject || workspaceId.length === 0 || importBusy)
            return false
        saveParentPath = Quickshell.env("HOME") || "/"
        saveFolderName = SavePlan.folderName(projectName)
            || "Wallpaper Project"
        saveAsChoosingParent = false
        saveAsOpened = true
        return true
    }

    function closeSaveAs() {
        saveAsOpened = false
        saveAsChoosingParent = false
    }

    function beginChoosingSaveParent() {
        if (!saveAsOpened) return false
        saveAsChoosingParent = true
        return true
    }

    function finishChoosingSaveParent() {
        saveAsChoosingParent = false
    }

    function chooseSaveParent(path) {
        saveParentPath = String(path || "")
        saveAsChoosingParent = false
    }

    function setSaveFolderName(name) {
        saveFolderName = String(name || "")
    }

    function finishSaveAsReview() {
        if (!savePreview.accepted) {
            NotificationService.showError("Save destination is invalid",
                savePreview.error, targetScreenName,
                "wallpaper-editor-save-destination", "Wallpaper Studio")
            return false
        }
        closeSaveAs()
        return true
    }

    function open(preferredScreenName) {
        closeTimer.stop()
        closing = false
        targetScreenName = ScreenService.resolve(preferredScreenName || "")
        opened = true
        inspectActiveProject()
        reconcileSelection()
    }

    function close() {
        if (!opened || closing) return
        cancelPicker()
        closeSaveAs()
        closing = true
        opened = false
        closeTimer.restart()
    }

    function toggle(preferredScreenName) {
        opened ? close() : open(preferredScreenName)
    }

    function snapshot() {
        return {
            opened: opened,
            closing: closing,
            targetScreenName: targetScreenName,
            projectId: activeProject?.project?.id || "",
            projectName: projectName,
            selectedAssetId: selectedAssetId,
            mediaItemCount: mediaItems.length,
            pickerOpened: pickerOpened,
            saveAsOpened: saveAsOpened,
            saveAsChoosingParent: saveAsChoosingParent,
            saveParentPath: saveParentPath,
            saveFolderName: saveFolderName,
            savePreview: JsonCopy.value(savePreview),
            importBusy: importBusy,
            importPhase: WallpaperEditorImportService.phase,
            importWorkspaceId: WallpaperEditorImportService.workspaceId,
            importReport: JsonCopy.value(importReport)
        }
    }

    onActiveProjectChanged: {
        reconcileSelection()
        if (opened) inspectActiveProject()
    }
    onMediaItemsChanged: reconcileSelection()

    Connections {
        target: WallpaperEditorImportService
        function onFinished(report) {
            if (report.imported?.length > 0) {
                root.pickerOpened = false
                root.inspectActiveProject()
                root.selectedAssetId = report.imported[0].id
            }
        }
    }

    Timer {
        id: closeTimer
        interval: Design.contentRevealDuration
        onTriggered: root.closing = false
    }
}
