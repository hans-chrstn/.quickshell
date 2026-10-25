import QtQuick
import Quickshell
import Quickshell.Io
import qs.services.wallpaper.projects

ShellRoot {
    id: root

    property int phase: 0
    property string projectId: ""
    property string workspaceId: ""
    property string copyJobId: ""
    readonly property string fixturePath: Quickshell.env("QS_PUBLICATION_TEST_FIXTURE")
    readonly property bool corruptStaging: Quickshell.env("QS_PUBLICATION_TEST_CORRUPT") === "1"
    property bool corruptionRequested: false
    readonly property string destinationParent: Quickshell.env("QS_PUBLICATION_TEST_PARENT")
    readonly property string destinationName: Quickshell.env("QS_PUBLICATION_TEST_NAME") || "published-project"

    function fail(message) {
        console.error("PUBLICATION_TEST_FAILED:" + message);
        Qt.exit(1);
    }

    Timer {
        interval: 20
        repeat: true
        running: true
        onTriggered: {
            if (root.phase === 0) {
                if (!WallpaperProjectService.loaded || !WallpaperDraftWorkspaceService.loaded)
                    return;
                root.projectId = WallpaperProjectService.createProject("Publication Integration Test");
                if (!root.projectId)
                    return root.fail("project-create");
                root.phase = 1;
            } else if (root.phase === 1) {
                if (WallpaperProjectService.dirty || WallpaperDraftWorkspaceService.busy)
                    return;
                root.workspaceId = WallpaperDraftWorkspaceService.createDraft(root.projectId);
                if (!root.workspaceId)
                    return root.fail("draft-create");
                root.phase = 2;
            } else if (root.phase === 2) {
                if (WallpaperDraftWorkspaceService.busy)
                    return;
                if (root.fixturePath) {
                    root.copyJobId = WallpaperDraftCopyService.enqueue(root.workspaceId, root.fixturePath, "script", "");
                    if (!root.copyJobId)
                        return root.fail("copy-request");
                    root.phase = 3;
                    return;
                }
                root.phase = 4;
            } else if (root.phase === 3) {
                const job = WallpaperDraftCopyService.snapshot().jobs[root.copyJobId];
                if (!job || job.state === "queued" || job.state === "running")
                    return;
                if (job.state !== "ready")
                    return root.fail("copy:" + (job.error || job.state));
                root.phase = 4;
            }
            if (root.phase === 4) {
                if (WallpaperDraftWorkspaceService.busy)
                    return;
                root.phase = 5;
                if (!WallpaperDraftPublicationService.request(root.workspaceId, root.destinationParent, root.destinationName))
                    return root.fail("publication-request:" + WallpaperDraftPublicationService.error);
            }
        }
    }

    Connections {
        target: WallpaperDraftPublicationService
        function onFinished(accepted, error) {
            console.log("PUBLICATION_TEST_RESULT:" + JSON.stringify(WallpaperDraftPublicationService.snapshot()));
            if (root.corruptStaging) {
                if (accepted)
                    root.fail("corrupted-project-was-published");
                Qt.quit();
                return;
            }
            if (!accepted)
                root.fail(error);
            Qt.quit();
        }
    }

    Connections {
        target: WallpaperDraftPublicationService
        function onStateChanged() {
            if (!root.corruptStaging || root.corruptionRequested || target.state !== "writing-staged-manifests")
                return;
            root.corruptionRequested = true;
            corruptor.command = ["truncate", "-s", "1", "--", target.plan.stagingPath + "/scripts/fixture.js"];
            corruptor.running = true;
        }
    }

    Process {
        id: corruptor
    }

    Timer {
        interval: 15000
        running: true
        onTriggered: root.fail("harness-timeout")
    }
}
