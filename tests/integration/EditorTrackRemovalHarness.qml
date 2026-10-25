import QtQuick
import QtQuick.Controls
import QtTest
import Quickshell
import qs.editor
import qs.services.wallpaper.projects

ShellRoot {
    Window {
        id: window
        width: 640
        height: 480
        visible: true

        Item {
            id: owner
            anchors.fill: parent
            focus: true
            property int escaped: 0
            Keys.onEscapePressed: escaped += 1

            EditorTrackMenu {
                id: trackMenu
                onDismissed: owner.forceActiveFocus()
            }
        }

        TestCase {
            name: "EditorTrackRemoval"
            when: window.visible && WallpaperProjectService.loaded
            property string projectId: ""
            property var menu: null
            property var dialog: null

            function initTestCase() {
                menu = findChild(trackMenu, "trackContextMenu");
                dialog = findChild(trackMenu, "trackRemovalConfirmation");
                verify(menu !== null);
                verify(dialog !== null);
            }

            function init() {
                projectId = WallpaperProjectService.createProject("Removal harness");
                verify(projectId.length > 0);
                const document = WallpaperProjectService.projectSnapshot(projectId);
                document.project.assets = [
                    {
                        id: "image",
                        name: "Image",
                        kind: "static",
                        sourcePath: "/fixture.png",
                        availability: "unresolved"
                    }
                ];
                document.project.durationMs = 10000;
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
                                assetId: "image",
                                startMs: 0,
                                durationMs: 1000,
                                sourceInMs: 0,
                                loop: false,
                                enabled: true
                            }
                        ]
                    },
                    {
                        id: "empty",
                        name: "Audio",
                        type: "audio",
                        enabled: true,
                        locked: false,
                        clips: []
                    }
                ];
                verify(WallpaperProjectService.upsertJson(JSON.stringify(document)), WallpaperProjectService.error);
                owner.escaped = 0;
                owner.forceActiveFocus();
            }

            function cleanup() {
                console.log("TRACK_REMOVAL_CASE:" + qtest_results.functionName + ":failed=" + qtest_results.failed);
                menu.close();
                dialog.close();
                tryCompare(menu, "visible", false);
                tryCompare(dialog, "visible", false);
                WallpaperProjectService.removeProject(projectId);
            }

            function cleanupTestCase() {
                tryCompare(WallpaperProjectService, "dirty", false);
                console.log("TRACK_REMOVAL_RESULT:passed=" + qtest_results.passCount + ",failed=" + qtest_results.failCount);
            }

            function openRemoval(trackId) {
                verify(trackMenu.openFor(trackId, owner, 20, 20));
                tryCompare(menu, "opened", true);
                tryCompare(menu.contentItem, "activeFocus", true);
                verify(menu.actions[0].enabled);
                keyClick(Qt.Key_Return);
                tryCompare(menu, "visible", false);
            }

            function current() {
                return WallpaperProjectService.projectSnapshot(projectId).project;
            }

            function test_emptyRemovesImmediately() {
                openRemoval("empty");
                compare(dialog.visible, false);
                compare(current().tracks.length, 1);
                compare(current().tracks[0].clips.length, 1);
            }

            function test_directEmptyRemovalCommitsImmediately() {
                verify(trackMenu.requestRemoval("empty"));
                compare(dialog.visible, false);
                compare(current().tracks.length, 1);
                compare(current().tracks[0].id, "visual");
            }

            function test_directPopulatedRemovalRequiresConfirmation() {
                const before = JSON.stringify(current());
                verify(trackMenu.requestRemoval("visual"));
                tryCompare(dialog, "opened", true);
                compare(JSON.stringify(current()), before);
                dialog.reject();
                tryCompare(dialog, "visible", false);
                compare(JSON.stringify(current()), before);
            }

            function test_cancelButtonRetainsEverything() {
                const before = JSON.stringify(current());
                openRemoval("visual");
                tryCompare(dialog, "opened", true);
                verify(dialog.message.indexOf("1 clip") >= 0);
                const cancel = findChild(dialog.contentItem, "confirmationCancel");
                verify(cancel !== null);
                mouseClick(cancel, cancel.width / 2, cancel.height / 2);
                tryCompare(dialog, "visible", false);
                compare(JSON.stringify(current()), before);
            }

            function test_escapeDoesNotReachEditor() {
                openRemoval("visual");
                tryCompare(dialog, "opened", true);
                keyClick(Qt.Key_Escape);
                tryCompare(dialog, "visible", false);
                compare(owner.escaped, 0);
                compare(current().tracks.length, 2);
            }

            function test_outsideClickDoesNotRemove() {
                openRemoval("visual");
                tryCompare(dialog, "opened", true);
                mouseClick(owner, 5, 5);
                tryCompare(dialog, "visible", false);
                compare(current().tracks.length, 2);
            }

            function test_returnDefaultsToCancel() {
                openRemoval("visual");
                tryCompare(dialog, "opened", true);
                compare(dialog.currentIndex, 0);
                keyClick(Qt.Key_Return);
                tryCompare(dialog, "visible", false);
                compare(current().tracks.length, 2);
            }

            function test_confirmButtonCommitsOnceAndKeepsMedia() {
                WallpaperTimelineService.selectAllClips();
                openRemoval("visual");
                tryCompare(dialog, "opened", true);
                const revision = WallpaperProjectService.revision;
                const accept = findChild(dialog.contentItem, "confirmationAccept");
                verify(accept !== null);
                mouseClick(accept, accept.width / 2, accept.height / 2);
                tryCompare(dialog, "visible", false);
                compare(WallpaperProjectService.revision, revision + 1);
                compare(current().tracks.length, 1);
                compare(current().tracks[0].id, "empty");
                compare(current().assets.length, 1);
                compare(current().durationMs, 10000);
                compare(WallpaperTimelineService.selection.clipIds.length, 0);
            }

            function test_keyboardConfirmation() {
                openRemoval("visual");
                tryCompare(dialog, "opened", true);
                keyClick(Qt.Key_Right);
                keyClick(Qt.Key_Return);
                tryCompare(dialog, "visible", false);
                compare(current().tracks.length, 1);
            }

            function test_changedTrackRejectsOldConfirmation() {
                openRemoval("visual");
                tryCompare(dialog, "opened", true);
                const document = WallpaperProjectService.projectSnapshot(projectId);
                document.project.tracks[0].clips[0].durationMs = 2000;
                verify(WallpaperProjectService.upsertJson(JSON.stringify(document)), WallpaperProjectService.error);
                dialog.accept();
                compare(current().tracks.length, 2);
                verify(WallpaperTimelineService.error.indexOf("changed") >= 0);
            }

            function test_projectSwitchRejectsOldConfirmation() {
                openRemoval("visual");
                tryCompare(dialog, "opened", true);
                const otherId = WallpaperProjectService.createProject("Other");
                const other = WallpaperProjectService.projectSnapshot(otherId);
                other.project.tracks = current().tracks;
                other.project.assets = current().assets;
                verify(WallpaperProjectService.upsertJson(JSON.stringify(other)));
                dialog.accept();
                compare(WallpaperProjectService.projectSnapshot(otherId).project.tracks.length, 2);
                compare(current().tracks.length, 2);
                WallpaperProjectService.removeProject(otherId);
            }

            function test_pendingSaveCannotReplaceNewerProject() {
                WallpaperProjectService.save();
                const nextId = WallpaperProjectService.createProject("Newer unsaved project");
                verify(nextId.length > 0);
                wait(650);
                compare(WallpaperProjectService.activeProjectId, nextId);
                verify(WallpaperProjectService.projectSnapshot(nextId) !== null);
                compare(WallpaperProjectService.projectSnapshot(nextId).project.name, "Newer unsaved project");
                verify(WallpaperProjectService.removeProject(nextId));
            }
        }
    }

    Timer {
        interval: 20000
        running: true
        onTriggered: {
            console.error("TRACK_REMOVAL_HARNESS_TIMEOUT");
            Qt.exit(1);
        }
    }
}
