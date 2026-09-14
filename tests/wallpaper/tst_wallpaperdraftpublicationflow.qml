import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperDraftPublicationFlow.js" as Flow

TestCase {
    name: "WallpaperDraftPublicationFlow"

    readonly property var context: ({
            plan: {
                sourceRootPath: "/draft",
                sourceManifestPath: "/draft/bundle.json",
                parentPath: "/projects",
                destinationPath: "/projects/demo",
                stagingPath: "/projects/.demo-staging",
                projectId: "project-1"
            },
            completedDocument: {
                workspace: {
                    files: []
                }
            },
            activeFile: null,
            transferTimeout: size => 30000
        })

    function test_preflightAdvancesWithoutSideEffects() {
        let action = Flow.next("checking-parent", 0, "", context);
        compare(action.kind, "run");
        compare(action.state, "checking-source");
        action = Flow.next("checking-staging", 0, "", context);
        compare(action.kind, "call");
        compare(action.name, "persist-saving");
    }

    function test_preflightFailureIsSpecific() {
        const action = Flow.next("checking-destination", 1, "", context);
        compare(action.kind, "fail");
        compare(action.message, "A file or folder already uses this project name");
    }

    function test_publicationRequiresMovedStagingAndReadableManifests() {
        let action = Flow.next("publishing", 0, "", context);
        compare(action.state, "verifying-staging-moved");
        action = Flow.next("verifying-staging-moved", 0, "", context);
        compare(action.state, "verifying-published");
        action = Flow.next("verifying-published", 0, "", context);
        compare(action.kind, "call");
        compare(action.name, "persist-completed");
    }

    function test_unknownStateFailsClosed() {
        const action = Flow.next("unexpected", 0, "", context);
        compare(action.kind, "fail");
        verify(action.message.includes("unexpected"));
    }
}
