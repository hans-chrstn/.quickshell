pragma Singleton

import QtQuick
import Quickshell
import "../../../core/JsonCopy.js" as JsonCopy

Singleton {
    id: root

    property bool pickerOpened: false
    property string initialPath: Quickshell.env("HOME") || "/"
    property string selectedPath: ""
    property string error: ""
    property int activeInspectionRequestId: 0
    readonly property bool busy: activeInspectionRequestId > 0 && WallpaperPublishedProjectInspectionService.busy && WallpaperPublishedProjectInspectionService.activeRequestId === activeInspectionRequestId
    readonly property real progress: busy ? WallpaperPublishedProjectInspectionService.progress : 0

    signal finished(bool accepted, string error, string projectId)

    function openPicker(path) {
        if (activeInspectionRequestId > 0)
            return false;
        if (WallpaperPublishedProjectInspectionService.readyForRequest)
            WallpaperPublishedProjectInspectionService.reset();
        initialPath = String(path || Quickshell.env("HOME") || "/");
        selectedPath = "";
        error = "";
        pickerOpened = true;
        return true;
    }

    function cancelPicker() {
        const requestId = activeInspectionRequestId;
        activeInspectionRequestId = 0;
        pickerOpened = false;
        selectedPath = "";
        error = "";
        if (requestId > 0)
            WallpaperPublishedProjectInspectionService.cancel(requestId);
        else if (WallpaperPublishedProjectInspectionService.readyForRequest)
            WallpaperPublishedProjectInspectionService.reset();
        return true;
    }

    function choose(path) {
        if (!pickerOpened || activeInspectionRequestId > 0)
            return false;
        selectedPath = String(path || "");
        error = "";
        const requestId = WallpaperPublishedProjectInspectionService.request(selectedPath);
        if (!requestId) {
            error = WallpaperPublishedProjectInspectionService.error || "Project inspection is not ready";
            return false;
        }
        activeInspectionRequestId = requestId;
        return true;
    }

    function commit(result) {
        const document = result?.projectDocument;
        const projectId = document?.project?.id || "";
        if (!document || !projectId)
            return reject("Validated project document is unavailable");
        if (!WallpaperProjectService.upsertJson(JSON.stringify(document)))
            return reject(WallpaperProjectService.error || "Project could not be added to the library");
        if (!WallpaperProjectService.selectProject(projectId))
            return reject(WallpaperProjectService.error || "Opened project could not be selected");
        activeInspectionRequestId = 0;
        pickerOpened = false;
        error = "";
        finished(true, "", projectId);
        return true;
    }

    function reject(message) {
        error = String(message || "Project could not be opened");
        finished(false, error, "");
        return false;
    }

    function snapshot() {
        return JsonCopy.value({
            pickerOpened: pickerOpened,
            initialPath: initialPath,
            selectedPath: selectedPath,
            activeInspectionRequestId: activeInspectionRequestId,
            busy: busy,
            progress: progress,
            error: error,
            inspection: WallpaperPublishedProjectInspectionService.snapshot()
        });
    }

    Connections {
        target: WallpaperPublishedProjectInspectionService
        function onFinished(accepted, inspectionError, result, requestId) {
            if (requestId !== root.activeInspectionRequestId)
                return;
            root.activeInspectionRequestId = 0;
            if (!accepted)
                root.reject(inspectionError);
            else
                root.commit(result);
        }
    }
}
