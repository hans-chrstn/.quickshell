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
    property bool warmRetained: false
    property string targetScreenName: ""
    readonly property string selectedAssetId: WallpaperEditorSelectionService.selectedAssetId
    property bool pickerOpened: false
    property bool saveAsOpened: false
    property bool saveAsChoosingParent: false
    property string saveParentPath: ""
    property string saveFolderName: ""
    readonly property bool importBusy: WallpaperEditorImportService.busy
    readonly property bool openProjectBusy: WallpaperEditorOpenService.busy
    readonly property bool savePreflightBusy: WallpaperDraftPublicationService.busy
    readonly property string savePreflightState: WallpaperDraftPublicationService.state
    readonly property string savePreflightError: WallpaperDraftPublicationService.error
    readonly property var importReport: WallpaperEditorImportService.report
    readonly property var activeProject: {
        const revision = WallpaperProjectService.revision;
        const id = WallpaperProjectService.activeProjectId;
        return id.length > 0 ? WallpaperProjectService.projectSnapshot(id) : null;
    }
    readonly property string projectName: activeProject?.project?.name || "Untitled Wallpaper"
    readonly property string workspaceId: {
        const projectId = activeProject?.project?.id || "";
        return projectId.length > 0 ? (WallpaperDraftWorkspaceService.workspaceForProject(projectId)?.id || "") : "";
    }
    readonly property var mediaItems: {
        const project = activeProject?.project;
        const diagnostics = WallpaperProjectAvailabilityService.diagnostics;
        if (!project)
            return [];
        const byId = ({});
        if (diagnostics.projectId === project.id) {
            for (const record of diagnostics.assets || [])
                byId[record.assetId] = record;
        }
        return project.assets.map(asset => {
            const resolved = byId[asset.id] || ({
                    state: "pending"
                });
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
            };
        });
    }
    readonly property var selectedAsset: mediaItems.find(asset => asset.id === selectedAssetId) || null
    readonly property bool saveFolderNameValid: SavePlan.folderName(saveFolderName).length > 0
    readonly property var savePreview: {
        const workspaceRevision = WallpaperDraftWorkspaceService.manifests;
        const registryRevision = WallpaperDraftWorkspaceService.workspaces;
        if (!saveAsOpened || workspaceId.length === 0)
            return {
                accepted: false,
                error: "Draft workspace is unavailable",
                plan: null
            };
        const snapshot = WallpaperDraftWorkspaceService.workspaceSnapshot(workspaceId);
        return SavePlan.create({
            parentPath: saveParentPath,
            folderName: saveFolderName,
            operationId: "preview"
        }, snapshot?.entry, snapshot?.manifest, 0);
    }

    function inspectActiveProject() {
        const id = activeProject?.project?.id || "";
        if (id.length > 0)
            WallpaperProjectAvailabilityService.inspect(id);
    }

    function reconcileSelection() {
        WallpaperEditorSelectionService.reconcile(activeProject);
    }

    function selectAsset(assetId) {
        return WallpaperEditorSelectionService.selectAsset(assetId);
    }

    function clearAssetSelection() {
        return WallpaperEditorSelectionService.clearKind("asset");
    }

    function removeSelectedAsset() {
        const projectId = activeProject?.project?.id || "";
        const assetId = selectedAssetId;
        if (projectId.length === 0 || assetId.length === 0 || importBusy)
            return false;
        const before = WallpaperProjectService.projectSnapshot(projectId);
        const removed = WallpaperProjectService.removeAsset(projectId, assetId);
        if (removed) {
            WallpaperTimelineService.recordHistory(before, WallpaperProjectService.projectSnapshot(projectId), "Remove media from project");
            WallpaperEditorSelectionService.clearKind("asset");
            inspectActiveProject();
            reconcileSelection();
        } else if (WallpaperProjectService.error.length > 0) {
            NotificationService.showError("Media could not be removed", WallpaperProjectService.error, targetScreenName, "wallpaper-editor-remove-media", "Wallpaper Studio");
        }
        return removed;
    }

    function newProject() {
        if (!WallpaperProjectService.loaded || importBusy || openProjectBusy || savePreflightBusy || pickerOpened || saveAsOpened)
            return false;
        const projectId = WallpaperProjectService.createProject("Untitled Wallpaper");
        if (projectId.length === 0) {
            NotificationService.showError("Project could not be created", WallpaperProjectService.error || "Wallpaper Studio is not ready", targetScreenName, "wallpaper-editor-new-project", "Wallpaper Studio");
            return false;
        }
        WallpaperEditorSelectionService.clear();
        inspectActiveProject();
        return true;
    }

    function openPicker() {
        if (importBusy || openProjectBusy)
            return false;
        if (!activeProject) {
            const projectId = WallpaperProjectService.createProject("Untitled Wallpaper");
            if (projectId.length === 0)
                return WallpaperEditorImportService.reject(WallpaperProjectService.error || "A wallpaper project could not be created");
        }
        WallpaperEditorImportService.clearReport();
        pickerOpened = true;
        return true;
    }

    function openProjectPicker() {
        if (importBusy || saveAsOpened || pickerOpened)
            return false;
        return WallpaperEditorOpenService.openPicker(activeProject?.project?.rootPath || "");
    }

    function cancelPicker() {
        pickerOpened = false;
        WallpaperEditorImportService.cancel();
    }

    function requestImport(paths) {
        const projectId = activeProject?.project?.id || "";
        return pickerOpened && WallpaperEditorImportService.request(projectId, paths);
    }

    function openSaveAs() {
        if (!activeProject || workspaceId.length === 0 || importBusy)
            return false;
        saveParentPath = Quickshell.env("HOME") || "/";
        saveFolderName = SavePlan.folderName(projectName) || "Wallpaper Project";
        WallpaperDraftPublicationService.reset();
        saveAsChoosingParent = false;
        saveAsOpened = true;
        return true;
    }

    function closeSaveAs() {
        const wasOpened = saveAsOpened || saveAsChoosingParent;
        saveAsOpened = false;
        saveAsChoosingParent = false;
        if (!WallpaperDraftPublicationService.busy)
            WallpaperDraftPublicationService.reset();
        return wasOpened;
    }

    function beginChoosingSaveParent() {
        if (!saveAsOpened)
            return false;
        saveAsChoosingParent = true;
        return true;
    }

    function finishChoosingSaveParent() {
        saveAsChoosingParent = false;
    }

    function chooseSaveParent(path) {
        saveParentPath = String(path || "");
        WallpaperDraftPublicationService.reset();
        saveAsChoosingParent = false;
    }

    function setSaveFolderName(name) {
        saveFolderName = String(name || "");
        WallpaperDraftPublicationService.reset();
    }

    function finishSaveAsReview() {
        if (!savePreview.accepted) {
            NotificationService.showError("Save destination is invalid", savePreview.error, targetScreenName, "wallpaper-editor-save-destination", "Wallpaper Studio");
            return false;
        }
        return WallpaperDraftPublicationService.request(workspaceId, saveParentPath, saveFolderName);
    }

    function open(preferredScreenName) {
        closeTimer.stop();
        warmTimer.stop();
        closing = false;
        targetScreenName = ScreenService.resolve(preferredScreenName || "");
        opened = true;
        // Preserve continuous demand when reopening a retained editor. If
        // retention were cleared first, its loader could unload between the
        // two assignments and defeat warm reuse.
        warmRetained = false;
        WallpaperPresentationService.setEditorState(true, false);
        inspectActiveProject();
        reconcileSelection();
    }

    function close() {
        if (!opened || closing)
            return false;
        closing = true;
        opened = false;
        WallpaperEditorOpenService.cancelPicker();
        cancelPicker();
        closeSaveAs();
        if (WallpaperProjectService.dirty)
            WallpaperProjectService.save();
        warmRetained = true;
        warmTimer.restart();
        WallpaperPresentationService.setEditorState(false, true);
        closeTimer.restart();
        return true;
    }

    function toggle(preferredScreenName) {
        opened ? close() : open(preferredScreenName);
    }

    function evictWarm(reason) {
        if (opened || closing || !warmRetained)
            return false;
        warmTimer.stop();
        warmRetained = false;
        return true;
    }

    function snapshot() {
        return {
            opened: opened,
            closing: closing,
            warmRetained: warmRetained,
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
            savePreflight: WallpaperDraftPublicationService.snapshot(),
            importBusy: importBusy,
            openProject: WallpaperEditorOpenService.snapshot(),
            importPhase: WallpaperEditorImportService.phase,
            importWorkspaceId: WallpaperEditorImportService.workspaceId,
            importReport: JsonCopy.value(importReport)
        };
    }

    onActiveProjectChanged: {
        reconcileSelection();
        if (opened)
            inspectActiveProject();
    }
    onMediaItemsChanged: reconcileSelection()

    Connections {
        target: WallpaperEditorImportService
        function onFinished(report) {
            if (report.imported?.length > 0) {
                root.pickerOpened = false;
                root.inspectActiveProject();
                WallpaperEditorSelectionService.selectAsset(report.imported[0].id);
            }
        }
    }

    Connections {
        target: WallpaperDraftPublicationService
        function onFinished(accepted, message) {
            if (!accepted) {
                NotificationService.showError("Project cannot be saved here", message, root.targetScreenName, "wallpaper-editor-save-preflight", "Wallpaper Studio");
            } else if (message.length > 0) {
                NotificationService.showWarning("Project saved with a warning", message, root.targetScreenName, "wallpaper-editor-save-warning", "Wallpaper Studio");
            }
        }
    }

    Connections {
        target: WallpaperEditorOpenService
        function onFinished(accepted, message, projectId) {
            if (accepted) {
                WallpaperEditorSelectionService.clear();
                root.inspectActiveProject();
                root.reconcileSelection();
            } else {
                NotificationService.showError("Project could not be opened", message, root.targetScreenName, "wallpaper-editor-open-project", "Wallpaper Studio");
            }
        }
    }

    Timer {
        id: closeTimer
        interval: Design.contentRevealDuration
        onTriggered: {
            root.closing = false;
            WallpaperPresentationService.setEditorState(false, false);
        }
    }

    Timer {
        id: warmTimer
        interval: Design.editorWarmRetentionMs
        onTriggered: root.warmRetained = false
    }
}
