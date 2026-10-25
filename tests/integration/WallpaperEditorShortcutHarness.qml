import QtQuick
import QtQuick.Controls
import QtTest
import Quickshell
import qs.editor
import qs.services.wallpaper.projects

ShellRoot {
    Window {
        id: window

        width: 1400
        height: 900
        visible: true

        WallpaperEditorSurface {
            id: surface

            anchors.fill: parent
        }

        TestCase {
            name: "WallpaperEditorShortcuts"
            when: window.visible && WallpaperProjectService.loaded

            property string projectId: ""
            property var timeline: null

            function current() {
                return WallpaperProjectService.projectSnapshot(projectId).project;
            }

            function initTestCase() {
                projectId = WallpaperProjectService.createProject("Shortcut harness");
                verify(projectId.length > 0);
                const document = WallpaperProjectService.projectSnapshot(projectId);
                document.project.durationMs = 60000;
                document.project.assets = [
                    {
                        id: "used",
                        name: "Used",
                        kind: "static",
                        sourcePath: "/used.png",
                        availability: "unresolved"
                    },
                    {
                        id: "loose",
                        name: "Loose",
                        kind: "static",
                        sourcePath: "/loose.png",
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
                                assetId: "used",
                                startMs: 0,
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
                        id: "marker",
                        name: "Marker",
                        timeMs: 500,
                        triggerType: "manual",
                        enabled: true
                    }
                ];
                verify(WallpaperProjectService.upsertJson(JSON.stringify(document)), WallpaperProjectService.error);
                timeline = findChild(surface, "editorTimeline");
                verify(timeline !== null);
                surface.forceActiveFocus();
                tryCompare(surface, "activeFocus", true);
            }

            function cleanupTestCase() {
                WallpaperProjectService.removeProject(projectId);
                console.log("EDITOR_SHORTCUT_RESULT:passed=" + qtest_results.passCount + ",failed=" + qtest_results.failCount);
            }

            function test_globalSelectionCommands() {
                verify(WallpaperEditorSelectionService.selectAsset("loose"));
                keyClick(Qt.Key_Delete);
                compare(current().assets.length, 1);
                compare(WallpaperEditorSelectionService.kind, "none");
                verify(WallpaperTimelineService.canUndo);
                keyClick(Qt.Key_Z, Qt.ControlModifier);
                compare(current().assets.length, 2);
                keyClick(Qt.Key_Y, Qt.ControlModifier);
                compare(current().assets.length, 1);

                verify(WallpaperEditorSelectionService.selectMarker("marker", false));
                keyClick(Qt.Key_Delete);
                compare(current().markers.length, 0);
                compare(WallpaperEditorSelectionService.kind, "none");

                verify(WallpaperTimelineService.selectClip("visual", "clip", "replace"));
                keyClick(Qt.Key_Delete);
                compare(current().tracks[0].clips.length, 0);
                verify(WallpaperTimelineService.canUndo);

                keyClick(Qt.Key_Z, Qt.ControlModifier);
                compare(current().tracks[0].clips.length, 1);
                keyClick(Qt.Key_Y, Qt.ControlModifier);
                compare(current().tracks[0].clips.length, 0);
            }

            function test_timelineNavigationCommands() {
                timeline.playheadMs = 23000;
                timeline.scrollX = 120;
                keyClick(Qt.Key_Home);
                compare(timeline.playheadMs, 0);
                compare(timeline.scrollX, 0);

                keyClick(Qt.Key_End);
                compare(timeline.playheadMs, 60000);
                compare(timeline.scrollX, timeline.viewport.maximumScrollX);
            }
        }
    }

    Timer {
        interval: 20000
        running: true
        onTriggered: {
            console.error("EDITOR_SHORTCUT_HARNESS_TIMEOUT");
            Qt.exit(1);
        }
    }
}
