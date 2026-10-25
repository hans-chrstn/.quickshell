import QtQuick
import Quickshell
import qs.services.wallpaper.projects

ShellRoot {
    id: root

    property bool started: false

    Timer {
        interval: 20
        repeat: true
        running: true
        onTriggered: {
            if (root.started || !WallpaperProjectService.loaded)
                return;
            root.started = true;
            const projectId = WallpaperProjectService.createProject("Timeline Harness");
            const document = WallpaperProjectService.projectSnapshot(projectId);
            document.project.durationMs = 10000;
            document.project.assets = [
                {
                    id: "video",
                    name: "Video",
                    kind: "video",
                    sourcePath: "/fixture.mp4",
                    availability: "unresolved"
                }
            ];
            document.project.tracks = [
                {
                    id: "visual",
                    name: "Visual",
                    type: "media",
                    enabled: true,
                    locked: false,
                    clips: [
                        {
                            id: "clip",
                            assetId: "video",
                            startMs: 1000,
                            durationMs: 2000,
                            sourceInMs: 0,
                            loop: false,
                            enabled: true
                        }
                    ]
                }
            ];
            if (!WallpaperProjectService.upsertJson(JSON.stringify(document)) || !WallpaperTimelineService.beginGesture("move", "clip", "visual", 0, 100, 8, 4000) || !WallpaperTimelineService.updateGesture(200, false) || !WallpaperTimelineService.finishGesture()) {
                console.error("TIMELINE_SERVICE_FAILED:" + WallpaperTimelineService.error);
                Qt.exit(1);
                return;
            }
            const updated = WallpaperProjectService.projectSnapshot(projectId);
            const status = WallpaperTimelineService.snapshot();
            console.log("TIMELINE_SERVICE_RESULT:" + JSON.stringify({
                startMs: updated.project.tracks[0].clips[0].startMs,
                gestureActive: status.gestureActive,
                completedGestureId: status.session.completedGestureId,
                revision: WallpaperProjectService.revision
            }));
            if (updated.project.tracks[0].clips[0].startMs !== 3000 || status.gestureActive || status.session.completedGestureId.length === 0) {
                console.error("TIMELINE_SERVICE_FAILED:unexpected-state");
                Qt.exit(1);
                return;
            }
            Qt.quit();
        }
    }

    Timer {
        interval: 10000
        running: true
        onTriggered: {
            console.error("TIMELINE_SERVICE_FAILED:timeout");
            Qt.exit(1);
        }
    }
}
