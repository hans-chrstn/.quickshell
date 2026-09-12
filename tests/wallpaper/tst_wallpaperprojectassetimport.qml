import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperProjectAssetImport.js" as AssetImport

TestCase {
    name: "WallpaperProjectAssetImport"

    function project(assets) {
        return { schemaVersion: 1, project: {
            id: "import", name: "Import", assets: assets || [],
            tracks: [], markers: [], userProperties: [], outputTargets: []
        } }
    }

    function ready(path, kind, codec) {
        return { sourcePath: path, media: {
            state: "ready", kind: kind, codec: codec || ""
        } }
    }

    function test_importsSupportedKindsWithStableUniqueIds() {
        const result = AssetImport.apply(project(), [
            ready("/media/ambient.png", "static", "png"),
            ready("/other/ambient.mp4", "video", "h264"),
            ready("/media/motion.gif", "animatedImage", "gif")
        ])
        verify(result.accepted)
        compare(result.imported.length, 3)
        compare(result.imported[0].id, "ambient")
        compare(result.imported[1].id, "ambient-2")
        compare(result.imported[2].kind, "animated-image")
        compare(result.document.project.assets.length, 3)
    }

    function test_preservesRequestedEmbeddedIdentityWithCollisionSafety() {
        const first = ready("/draft/media/sky.png", "static", "png")
        first.assetId = "source-sky"
        const second = ready("/draft/media/cloud.png", "static", "png")
        second.assetId = "source-sky"
        const result = AssetImport.apply(project(), [first, second])
        verify(result.accepted)
        compare(result.imported[0].id, "source-sky")
        compare(result.imported[1].id, "source-sky-2")
    }

    function test_reportsDuplicatesUnavailableAndUnsupported() {
        const existing = [{ id: "still", kind: "static",
            sourcePath: "/media/still.png" }]
        const result = AssetImport.apply(project(existing), [
            ready("/media/still.png", "static", "png"),
            { sourcePath: "/gone.mp4", media: {
                state: "failed", error: "gone" } },
            ready("/media/animated.webp", "animatedImage", "webp"),
            ready("/media/new.png", "static", "png")
        ])
        verify(result.accepted)
        compare(result.imported.length, 1)
        compare(result.skipped.length, 3)
        compare(result.skipped[0].reason, "duplicate")
        compare(result.skipped[1].reason, "unavailable")
        compare(result.skipped[2].reason, "unsupported")
    }

    function test_rejectsInvalidEmptyAndOversizedBatches() {
        verify(!AssetImport.apply(project(), "bad").accepted)
        verify(!AssetImport.apply(project(), []).accepted)
        const candidates = []
        for (let index = 0; index <= AssetImport.maximumImportBatch; ++index)
            candidates.push(ready("/media/" + index + ".png", "static", "png"))
        verify(!AssetImport.apply(project(), candidates).accepted)
    }

    function test_projectLimitProducesExplicitSkip() {
        const assets = []
        for (let index = 0; index < 512; ++index)
            assets.push({ id: "existing-" + index, kind: "static",
                sourcePath: "/media/existing-" + index + ".png" })
        const result = AssetImport.apply(project(assets), [
            ready("/media/extra.png", "static", "png")
        ])
        verify(!result.accepted)
        compare(result.skipped[0].reason, "project-limit")
        compare(result.document.project.assets.length, 512)
    }
}
