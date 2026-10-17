import QtQuick
import Quickshell
import qs.services.wallpaper.projects

ShellRoot {
    id: root

    property bool started: false
    property string firstProjectId: ""
    property string secondProjectId: ""

    function fail(message) {
        console.error("EDITOR_SELECTION_FAILED:" + message);
        Qt.exit(1);
    }

    function expect(condition, message) {
        if (!condition) {
            fail(message);
            return false;
        }
        return true;
    }

    Timer {
        interval: 20
        repeat: true
        running: true
        onTriggered: {
            if (root.started || !WallpaperProjectService.loaded)
                return;
            root.started = true;
            root.firstProjectId = WallpaperProjectService.createProject("Selection harness");
            if (!root.expect(root.firstProjectId.length > 0, "project-create"))
                return;
            const document = WallpaperProjectService.projectSnapshot(root.firstProjectId);
            document.project.durationMs = 10000;
            document.project.assets = [
                {
                    id: "asset-a",
                    name: "Asset A",
                    kind: "static",
                    sourcePath: "/fixture-a.png",
                    availability: "unresolved"
                },
                {
                    id: "asset-b",
                    name: "Asset B",
                    kind: "static",
                    sourcePath: "/fixture-b.png",
                    availability: "unresolved"
                }
            ];
            document.project.tracks = [
                {
                    id: "track-a",
                    name: "Media",
                    type: "media",
                    enabled: true,
                    locked: false,
                    clips: [
                        {
                            id: "clip-a",
                            assetId: "asset-a",
                            startMs: 0,
                            durationMs: 1000,
                            sourceInMs: 0,
                            loop: false,
                            enabled: true
                        },
                        {
                            id: "clip-b",
                            assetId: "asset-b",
                            startMs: 1000,
                            durationMs: 1000,
                            sourceInMs: 0,
                            loop: false,
                            enabled: true
                        }
                    ]
                }
            ];
            document.project.markers = [
                {
                    id: "marker-a",
                    name: "Marker",
                    timeMs: 500,
                    triggerType: "manual",
                    enabled: true
                }
            ];
            if (!root.expect(WallpaperProjectService.upsertJson(JSON.stringify(document)), "project-upsert"))
                return;
            if (!root.expect(WallpaperEditorSelectionService.selectAsset("asset-a"), "asset-select"))
                return;
            if (!root.expect(WallpaperEditorSelectionService.kind === "asset" && WallpaperEditorService.selectedAssetId === "asset-a" && WallpaperTimelineService.selection.clipIds.length === 0, "asset-compatibility"))
                return;
            if (!root.expect(WallpaperEditorSelectionService.selectMarker("marker-a", true), "marker-select"))
                return;
            if (!root.expect(WallpaperEditorSelectionService.kind === "marker" && WallpaperEditorSelectionService.selectedAssetId === "", "marker-exclusivity"))
                return;
            if (!root.expect(WallpaperTimelineService.selectClip("track-a", "clip-a", "replace"), "clip-select"))
                return;
            if (!root.expect(WallpaperEditorSelectionService.kind === "clips" && WallpaperEditorSelectionService.selectedMarkerId === "" && WallpaperTimelineService.selection.clipIds[0] === "clip-a", "clip-exclusivity"))
                return;
            if (!root.expect(WallpaperTimelineService.selectClip("track-a", "clip-b", "add") && WallpaperTimelineService.selection.clipIds.length === 2, "clip-multiselect"))
                return;
            if (!root.expect(WallpaperTimelineService.selectTrack("track-a") && WallpaperEditorSelectionService.kind === "track" && WallpaperTimelineService.selection.clipIds.length === 0, "track-select"))
                return;
            if (!root.expect(WallpaperEditorService.newProject(), "new-project-command"))
                return;
            root.secondProjectId = WallpaperProjectService.activeProjectId;
            if (!root.expect(root.secondProjectId.length > 0 && root.secondProjectId !== root.firstProjectId && WallpaperEditorSelectionService.kind === "none" && WallpaperEditorSelectionService.selection.projectId === root.secondProjectId, "project-switch-clear"))
                return;
            console.log("EDITOR_SELECTION_RESULT:passed");
            Qt.quit();
        }
    }

    Timer {
        interval: 10000
        running: true
        onTriggered: root.fail("timeout")
    }
}
