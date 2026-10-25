import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperDraftCopyPlan.js" as CopyPlan
import "../../services/wallpaper/projects/WallpaperProjectBundleModel.js" as Bundle

TestCase {
    name: "WallpaperDraftCopyPlan"

    function fixture() {
        return {
            workspace: { id: "draft-one", projectId: "project-one",
                rootPath: "/managed/draft-one" },
            manifest: Bundle.create("draft-one", "project-one", 1)
        }
    }

    function test_buildsContainedSourceCopyPlan() {
        const value = fixture()
        const result = CopyPlan.create({ sourcePath: "/source/sky loop.mp4",
            role: "media", assetId: "sky" }, value.workspace, value.manifest)
        verify(result.accepted)
        compare(result.plan.relativePath, "media/sky loop.mp4")
        compare(result.plan.destinationPath,
            "/managed/draft-one/media/sky loop.mp4")
        compare(result.plan.temporaryPath,
            "/managed/draft-one/media/sky loop.mp4.partial-sky")
    }

    function test_resolvesPathAndIdentityCollisionsDeterministically() {
        const value = fixture()
        value.manifest = Bundle.appendFile(value.manifest, {
            id: "sky", role: "media", relativePath: "media/sky.png",
            originalSourcePath: "/old/sky.png", state: "ready"
        }, 2).document
        const result = CopyPlan.create({ sourcePath: "/new/sky.png",
            role: "media", assetId: "sky" }, value.workspace, value.manifest)
        verify(result.accepted)
        compare(result.plan.fileId, "sky-2")
        compare(result.plan.relativePath, "media/sky-2.png")
        verify(!CopyPlan.create({ sourcePath: "/old/sky.png",
            role: "media", assetId: "duplicate" }, value.workspace,
            value.manifest).accepted)
    }

    function test_rejectsUnsafeUnsupportedAndMismatchedRequests() {
        const value = fixture()
        verify(!CopyPlan.create({ sourcePath: "relative.png", role: "media",
            assetId: "asset" }, value.workspace, value.manifest).accepted)
        verify(!CopyPlan.create({ sourcePath: "/a.png", role: "proxy",
            assetId: "asset" }, value.workspace, value.manifest).accepted)
        verify(!CopyPlan.create({ sourcePath: "/a.png", role: "media" },
            value.workspace, value.manifest).accepted)
        value.workspace.projectId = "other"
        verify(!CopyPlan.create({ sourcePath: "/a.png", role: "media",
            assetId: "asset" }, value.workspace, value.manifest).accepted)
    }

    function test_boundsLongNamesAndPermitsInertScripts() {
        const value = fixture()
        const longName = "/source/" + "a".repeat(300) + ".gif"
        const media = CopyPlan.create({ sourcePath: longName, role: "media",
            assetId: "long" }, value.workspace, value.manifest)
        verify(media.accepted)
        verify(media.plan.relativePath.length <= 226)
        const script = CopyPlan.create({ sourcePath: "/source/weather.js",
            role: "script" }, value.workspace, value.manifest)
        verify(script.accepted)
        compare(script.plan.relativePath, "scripts/weather.js")
    }

    function test_bundleUpdateIsImmutableAndStateBounded() {
        let document = Bundle.create("draft-one", "project-one", 1)
        document = Bundle.appendFile(document, { id: "copy", role: "media",
            relativePath: "media/a.png", originalSourcePath: "/a.png",
            assetId: "a", state: "copying" }, 2).document
        const ready = Bundle.updateFile(document, "copy", { state: "ready",
            sizeBytes: 20, identity: "sha256:abc", error: "" }, 3)
        verify(ready.accepted)
        compare(ready.document.workspace.files[0].state, "ready")
        compare(document.workspace.files[0].state, "copying")
        verify(!Bundle.updateFile(document, "missing", { state: "ready" }, 3)
            .accepted)
        verify(!Bundle.updateFile(document, "copy", { state: "invented" }, 3)
            .accepted)
        const removed = Bundle.removeFile(ready.document, "copy", 4)
        verify(removed.accepted)
        compare(removed.document.workspace.files.length, 0)
        compare(ready.document.workspace.files.length, 1)
    }
}
