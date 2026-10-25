import QtQuick
import Quickshell
import qs.services.wallpaper
import qs.services.wallpaper.projects

ShellRoot {
    id: root

    property bool started: false
    property int openFinishedCount: 0
    property int originalSaveCount: 0
    property string projectId: ""

    function fail(reason) {
        console.error("EDITOR_CLOSE_FAILED:" + reason);
        Qt.exit(1);
    }

    function expect(condition, reason) {
        if (!condition) {
            fail(reason);
            return false;
        }
        return true;
    }

    function begin() {
        projectId = WallpaperProjectService.createProject("Close Contract");
        if (!expect(projectId.length > 0, "project-create"))
            return;
        if (!expect(WallpaperProjectService.dirty, "project-dirty"))
            return;
        originalSaveCount = WallpaperProjectService.saveCount;
        WallpaperEditorService.open("");
        if (!expect(WallpaperEditorService.opened, "editor-open"))
            return;
        if (!expect(WallpaperEditorOpenService.openPicker("/tmp"), "picker-open"))
            return;
        if (!expect(WallpaperEditorOpenService.choose("/tmp/quickshell-editor-close-missing-project"), "inspection-request"))
            return;
        if (!expect(WallpaperEditorOpenService.busy, "inspection-busy-before-close"))
            return;
        if (!expect(WallpaperEditorService.close(), "close-accepted"))
            return;
        if (!expect(!WallpaperEditorService.opened, "editor-closed-immediately"))
            return;
        if (!expect(WallpaperEditorService.closing, "close-handoff-active"))
            return;
        if (!expect(!WallpaperEditorOpenService.pickerOpened, "picker-dismissed"))
            return;
        if (!expect(!WallpaperEditorOpenService.busy, "inspection-cancelled"))
            return;
        if (!expect(!WallpaperProjectService.dirty, "autosave-completed"))
            return;
        if (!expect(WallpaperProjectService.saveCount === originalSaveCount + 1, "autosave-owner"))
            return;
        settle.restart();
    }

    Timer {
        interval: 20
        repeat: true
        running: !root.started
        onTriggered: {
            if (!WallpaperProjectService.loaded)
                return;
            root.started = true;
            stop();
            root.begin();
        }
    }

    Connections {
        target: WallpaperEditorOpenService
        function onFinished(accepted, error, openedProjectId) {
            root.openFinishedCount += 1;
        }
    }

    Timer {
        id: settle
        interval: 1200
        onTriggered: {
            if (!root.expect(root.openFinishedCount === 0, "stale-inspection-completion"))
                return;
            if (!root.expect(!WallpaperEditorService.opened && !WallpaperEditorService.closing, "close-handoff-completed"))
                return;
            if (!root.expect(!WallpaperPresentationService.editorActive, "presentation-released"))
                return;
            if (!root.expect(!WallpaperEditorOpenService.pickerOpened && !WallpaperEditorOpenService.busy, "picker-remained-closed"))
                return;
            console.log("EDITOR_CLOSE_RESULT:" + JSON.stringify({
                editor: WallpaperEditorService.snapshot(),
                openProject: WallpaperEditorOpenService.snapshot(),
                inspection: WallpaperPublishedProjectInspectionService.snapshot(),
                openFinishedCount: root.openFinishedCount
            }));
            Qt.quit();
        }
    }

    Timer {
        interval: 5000
        running: true
        onTriggered: root.fail("timeout")
    }
}
