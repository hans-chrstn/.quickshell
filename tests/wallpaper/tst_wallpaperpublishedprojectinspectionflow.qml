import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperPublishedProjectInspectionFlow.js" as Flow

TestCase {
    name: "WallpaperPublishedProjectInspectionFlow"

    readonly property var context: ({
            rootPath: "/projects/Ambient"
        })

    function test_successPathUsesDirectArgumentCommands() {
        let action = Flow.next("checking-root", 0, "", context);
        compare(action.kind, "run");
        compare(action.state, "reading-project");
        compare(action.command[2], "/projects/Ambient/project.json");

        action = Flow.next("reading-project", 0, "{}", context);
        compare(action.name, "parse-project");
        action = Flow.next("reading-bundle", 0, "{}", context);
        compare(action.name, "parse-bundle");
        action = Flow.next("checking-symlinks", 0, "", context);
        compare(action.state, "scanning-inventory");
        compare(action.command[4], "-printf");
        compare(action.command[5], "%P\\n");
    }

    function test_symlinkAndProcessFailuresFailClosed() {
        let action = Flow.next("checking-symlinks", 0, "/projects/Ambient/media/link", context);
        compare(action.kind, "fail");
        verify(action.message.includes("symbolic link"));
        action = Flow.next("reading-bundle", 1, "", context);
        compare(action.kind, "fail");
        verify(action.message.includes("could not be read"));
    }

    function test_unknownStateFailsClosed() {
        const action = Flow.next("unknown", 0, "", context);
        compare(action.kind, "fail");
        verify(action.message.includes("unknown"));
    }
}
