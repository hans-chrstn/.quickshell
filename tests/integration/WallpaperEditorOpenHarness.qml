import QtQuick
import Quickshell
import qs.services.wallpaper.projects

ShellRoot {
    id: root

    readonly property string projectPath: Quickshell.env("QS_PROJECT_OPEN_PATH")
    readonly property bool expectFailure: Quickshell.env("QS_PROJECT_OPEN_EXPECT_FAILURE") === "1"
    property bool started: false

    Timer {
        interval: 20
        repeat: true
        running: true
        onTriggered: {
            if (root.started || !WallpaperProjectService.loaded)
                return;
            root.started = true;
            if (!WallpaperEditorOpenService.openPicker(projectPath) || !WallpaperEditorOpenService.choose(projectPath)) {
                console.error("PROJECT_OPEN_FAILED:request");
                Qt.exit(1);
            }
        }
    }

    Connections {
        target: WallpaperEditorOpenService
        function onFinished(accepted, error, projectId) {
            if (root.expectFailure) {
                console.log("PROJECT_OPEN_REJECTION:" + error);
                if (accepted || WallpaperProjectService.activeProjectId) {
                    console.error("PROJECT_OPEN_FAILED:rejection-mutated-library");
                    Qt.exit(1);
                    return;
                }
                Qt.quit();
                return;
            }
            const project = WallpaperProjectService.projectSnapshot(projectId);
            console.log("PROJECT_OPEN_RESULT:" + JSON.stringify({
                accepted: accepted,
                error: error,
                projectId: projectId,
                selectedId: WallpaperProjectService.activeProjectId,
                rootPath: project?.project?.rootPath || "",
                assetCount: project?.project?.assets?.length || 0
            }));
            if (!accepted || !project || WallpaperProjectService.activeProjectId !== projectId || project.project.rootPath !== root.projectPath) {
                console.error("PROJECT_OPEN_FAILED:commit");
                Qt.exit(1);
                return;
            }
            Qt.quit();
        }
    }

    Timer {
        interval: 15000
        running: true
        onTriggered: {
            console.error("PROJECT_OPEN_FAILED:timeout");
            Qt.exit(1);
        }
    }
}
