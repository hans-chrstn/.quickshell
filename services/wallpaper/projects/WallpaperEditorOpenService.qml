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
    readonly property bool busy: WallpaperPublishedProjectInspectionService.busy
    readonly property real progress: WallpaperPublishedProjectInspectionService.progress

    signal finished(bool accepted, string error, string projectId)

    function openPicker(path) {
        if (busy)
            return false;
        WallpaperPublishedProjectInspectionService.reset();
        initialPath = String(path || Quickshell.env("HOME") || "/");
        selectedPath = "";
        error = "";
        pickerOpened = true;
        return true;
    }

    function cancelPicker() {
        if (busy)
            return false;
        pickerOpened = false;
        selectedPath = "";
        error = "";
        WallpaperPublishedProjectInspectionService.reset();
        return true;
    }

    function choose(path) {
        if (!pickerOpened || busy)
            return false;
        selectedPath = String(path || "");
        error = "";
        return WallpaperPublishedProjectInspectionService.request(selectedPath);
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
            busy: busy,
            progress: progress,
            error: error,
            inspection: WallpaperPublishedProjectInspectionService.snapshot()
        });
    }

    Connections {
        target: WallpaperPublishedProjectInspectionService
        function onFinished(accepted, inspectionError, result) {
            if (!accepted)
                root.reject(inspectionError);
            else
                root.commit(result);
        }
    }
}
