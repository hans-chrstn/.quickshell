import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperProjectBundleModel.js" as Bundle

TestCase {
    name: "WallpaperProjectBundleModel"

    function readyFile(id, role, relative, source, assetId) {
        return { id: id, role: role, relativePath: relative,
            originalSourcePath: source || "", assetId: assetId || "",
            sizeBytes: 42, identity: "identity", state: "ready" }
    }

    function test_createsBoundedDraftAndCategorizedLayout() {
        const document = Bundle.create("draft-one", "project-one", 100)
        compare(document.schemaVersion, 1)
        compare(document.workspace.state, "draft")
        compare(document.workspace.createdAtMs, 100)
        compare(Bundle.directoryNames.media, "media")
        compare(Bundle.directoryNames.proxies, "proxies")

        const media = Bundle.appendFile(document,
            readyFile("image", "media", "media/image.png", "/source/image.png"), 110)
        verify(media.accepted)
        compare(media.document.workspace.revision, 1)
        compare(media.document.workspace.files[0].originalSourcePath,
            "/source/image.png")
        compare(document.workspace.files.length, 0)

        const proxy = Bundle.appendFile(media.document,
            readyFile("proxy", "proxy", "proxies/image.mp4", "", "image"), 120)
        verify(proxy.accepted)
        compare(proxy.document.workspace.files[1].originalSourcePath, "")
    }

    function test_rejectsTraversalRoleMismatchAndCollisions() {
        let document = Bundle.create("draft", "project", 1)
        verify(!Bundle.appendFile(document,
            readyFile("escape", "media", "../image.png", "/image.png"), 2).accepted)
        verify(!Bundle.appendFile(document,
            readyFile("wrong", "media", "audio/image.png", "/image.png"), 2).accepted)
        verify(!Bundle.appendFile(document,
            readyFile("directory", "media", "media", "/image.png"), 2).accepted)
        verify(!Bundle.appendFile(document, {
            id: "state", role: "media", relativePath: "media/a.png",
            originalSourcePath: "/a.png", state: "complete"
        }, 2).accepted)
        document = Bundle.appendFile(document,
            readyFile("one", "media", "media/a.png", "/a.png"), 2).document
        verify(!Bundle.appendFile(document,
            readyFile("one", "media", "media/b.png", "/b.png"), 3).accepted)
        verify(!Bundle.appendFile(document,
            readyFile("two", "media", "media/a.png", "/c.png"), 3).accepted)
    }

    function test_saveRequiresReadyFilesAndAbsoluteDestination() {
        let document = Bundle.create("draft", "project", 1)
        document = Bundle.appendFile(document, {
            id: "copy", role: "media", relativePath: "media/a.png",
            originalSourcePath: "/a.png", state: "copying"
        }, 2).document
        verify(!Bundle.beginSave(document, "/save/project", 3).accepted)
        document.workspace.files[0].state = "ready"
        verify(!Bundle.beginSave(document, "relative", 3).accepted)
        const saving = Bundle.beginSave(document, "/save/project", 3)
        verify(saving.accepted)
        compare(saving.document.workspace.state, "saving")
        const saved = Bundle.completeSave(saving.document, 4)
        verify(saved.accepted)
        compare(saved.document.workspace.state, "saved")
        compare(saved.document.workspace.savedRevision,
            saved.document.workspace.revision)
        verify(!Bundle.completeSave(saved.document, 5).accepted)
    }

    function test_recoversInterruptedCopyAndSaveDeterministically() {
        let document = Bundle.create("draft", "project", 1)
        document = Bundle.appendFile(document, {
            id: "copy", role: "media", relativePath: "media/a.png",
            originalSourcePath: "/a.png", state: "copying"
        }, 2).document
        document.workspace.state = "saving"
        const recovered = Bundle.recoverInterrupted(document, 10)
        verify(recovered.accepted)
        compare(recovered.document.workspace.state, "draft")
        compare(recovered.document.workspace.files[0].state, "failed")
        verify(recovered.document.workspace.lastError.indexOf("interrupted") >= 0)
    }

    function test_rejectsMalformedFutureAndOversizedDocuments() {
        verify(!Bundle.parse(null).accepted)
        verify(!Bundle.parse({ workspace: {} }).accepted)
        verify(!Bundle.parse({ schemaVersion: 2, workspace: {} }).accepted)
        verify(!Bundle.parse({ schemaVersion: 1,
            workspace: { files: "bad" } }).accepted)
        const invalid = Bundle.create("draft", "project", 1)
        invalid.workspace.state = "invented"
        invalid.workspace.files = [{ id: "bad", role: "executable",
            relativePath: "scripts/a.sh", state: "complete" }]
        verify(!Bundle.parse(invalid).accepted)
        const document = Bundle.create("draft", "project", 1)
        for (let index = 0; index <= Bundle.maximumFiles; ++index)
            document.workspace.files.push(readyFile("f-" + index,
                "media", "media/" + index + ".png", "/" + index + ".png"))
        verify(!Bundle.parse(document).accepted)
    }
}
