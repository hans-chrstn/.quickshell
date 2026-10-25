import QtQuick
import QtQuick.Controls
import QtTest
import Quickshell
import qs.modules.editor
import qs.services.wallpaper.projects

ShellRoot {
    Window {
        id: window

        width: 1400
        height: 900
        visible: true

        QtObject {
            id: editorContext

            property real availableWidth: window.width
            property real availableHeight: window.height
            property bool expanded: true
            property real expansionProgress: 1
        }

        WallpaperEditorModule {
            id: editorModule

            anchors.fill: parent
            context: editorContext
        }

        TestCase {
            name: "WallpaperEditorCloseInteraction"
            when: window.visible && WallpaperProjectService.loaded

            property string projectId: ""
            property var closeButton: null

            function initTestCase() {
                projectId = WallpaperProjectService.createProject("Close Interaction");
                verify(projectId.length > 0);
                WallpaperEditorService.open("");
                tryCompare(editorModule, "enabled", true);
                closeButton = findChild(editorModule, "editorCloseButton");
                verify(closeButton !== null);
                editorModule.forceActiveFocus();
                tryCompare(editorModule, "activeFocus", true);
            }

            function cleanupTestCase() {
                if (WallpaperEditorService.opened)
                    WallpaperEditorService.close();
                WallpaperProjectService.removeProject(projectId);
                console.log("EDITOR_CLOSE_INTERACTION_RESULT:passed=" + qtest_results.passCount + ",failed=" + qtest_results.failCount);
            }

            function test_repeatedEscapeCancellationAndClose() {
                for (let iteration = 0; iteration < 8; iteration += 1) {
                    if (!WallpaperEditorService.opened) {
                        WallpaperEditorService.open("");
                        tryCompare(editorModule, "enabled", true);
                    }
                    verify(WallpaperEditorOpenService.openPicker("/tmp"));
                    verify(WallpaperEditorOpenService.choose("/tmp/quickshell-editor-close-interaction-missing-" + iteration));
                    verify(WallpaperEditorOpenService.busy);
                    verify(closeButton.enabled);

                    editorModule.forceActiveFocus();
                    keyClick(Qt.Key_Escape);
                    compare(WallpaperEditorOpenService.pickerOpened, false);
                    compare(WallpaperEditorOpenService.busy, false);
                    compare(WallpaperEditorService.opened, true);
                    tryCompare(WallpaperPublishedProjectInspectionService, "readyForRequest", true);

                    editorModule.forceActiveFocus();
                    tryCompare(editorModule, "activeFocus", true);
                    keyClick(Qt.Key_Escape);
                    compare(WallpaperEditorService.opened, false);
                    verify(WallpaperEditorService.closing);
                    tryCompare(WallpaperEditorService, "closing", false);
                }
                compare(WallpaperPublishedProjectInspectionService.cancelCount, 8);
                compare(WallpaperPublishedProjectInspectionService.requestCount, 8);
            }
        }
    }

    Timer {
        interval: 20000
        running: true
        onTriggered: {
            console.error("EDITOR_CLOSE_INTERACTION_TIMEOUT");
            Qt.exit(1);
        }
    }
}
