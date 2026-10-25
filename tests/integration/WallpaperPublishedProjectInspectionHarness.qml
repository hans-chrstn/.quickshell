import QtQuick
import Quickshell
import qs.services.wallpaper.projects

ShellRoot {
    id: root

    readonly property string projectPath: Quickshell.env("QS_PROJECT_INSPECTION_PATH")

    Component.onCompleted: {
        if (!WallpaperPublishedProjectInspectionService.request(projectPath)) {
            console.error("PROJECT_INSPECTION_FAILED:request");
            Qt.exit(1);
        }
    }

    Connections {
        target: WallpaperPublishedProjectInspectionService
        function onFinished(accepted, error, result) {
            console.log("PROJECT_INSPECTION_RESULT:" + JSON.stringify(target.snapshot()));
            if (!accepted) {
                console.error("PROJECT_INSPECTION_FAILED:" + error);
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
            console.error("PROJECT_INSPECTION_FAILED:timeout");
            Qt.exit(1);
        }
    }
}
