import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperDraftRegistry.js" as Registry

TestCase {
    name: "WallpaperDraftRegistry"
    readonly property string base: "/data/wallpaper-project-drafts"

    function entry(id, project) {
        return { id: id, projectId: project, rootPath: "/forged",
            manifestPath: "/forged/manifest", createdAtMs: 1, updatedAtMs: 2 }
    }

    function test_derivesContainedPathsAndPreservesOrder() {
        let document = Registry.empty()
        document = Registry.upsert(document, entry("draft-a", "project-a"), base).document
        document = Registry.upsert(document, entry("draft-b", "project-b"), base).document
        compare(document.workspaces.length, 2)
        compare(document.workspaces[0].rootPath,
            base + "/draft-a")
        compare(document.workspaces[0].manifestPath,
            base + "/draft-a/bundle.json")
        const updated = Registry.upsert(document,
            Object.assign(entry("draft-a", "project-a"), { updatedAtMs: 9 }), base)
        compare(updated.document.workspaces[0].updatedAtMs, 9)
        compare(updated.document.workspaces[1].id, "draft-b")
    }

    function test_rejectsMalformedDuplicatesAndProjectAliases() {
        verify(!Registry.parse(null, base).accepted)
        verify(!Registry.parse({ schemaVersion: 2, workspaces: [] }, base).accepted)
        verify(!Registry.parse({ schemaVersion: 1, workspaces: "bad" }, base).accepted)
        verify(!Registry.parse({ schemaVersion: 1, workspaces: [
            entry("same", "a"), entry("same", "b") ] }, base).accepted)
        let document = Registry.upsert(Registry.empty(),
            entry("draft-a", "project"), base).document
        verify(!Registry.upsert(document,
            entry("draft-b", "project"), base).accepted)
    }

    function test_removeIsImmutableAndUnknownIsNoop() {
        const original = Registry.upsert(Registry.empty(),
            entry("draft-a", "project-a"), base).document
        const removed = Registry.remove(original, "draft-a", base)
        verify(removed.accepted)
        compare(removed.document.workspaces.length, 0)
        compare(original.workspaces.length, 1)
        compare(Registry.remove(original, "unknown", base)
            .document.workspaces.length, 1)
    }

    function test_enforcesWorkspaceLimit() {
        const document = Registry.empty()
        for (let index = 0; index < Registry.maximumWorkspaces; ++index)
            document.workspaces.push(entry("draft-" + index, "project-" + index))
        verify(Registry.parse(document, base).accepted)
        verify(!Registry.upsert(document,
            entry("overflow", "overflow"), base).accepted)
    }
}
