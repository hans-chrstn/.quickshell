import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperDraftDerivativePlan.js" as Plan
import "../../services/wallpaper/projects/WallpaperProjectBundleModel.js" as Bundle

TestCase {
    name: "WallpaperDraftDerivativePlan"

    readonly property string hash:
        "sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

    function fixture(fileChanges) {
        const workspace = { id: "draft-one", projectId: "project-one",
            rootPath: "/data/drafts/draft-one" }
        const manifest = Bundle.create(workspace.id, workspace.projectId, 1)
        const added = Bundle.appendFile(manifest, Object.assign({
            id: "sky", assetId: "sky", role: "media",
            relativePath: "media/sky.mp4",
            originalSourcePath: "/original/sky.mp4", sizeBytes: 42,
            identity: hash, state: "ready", error: ""
        }, fileChanges || ({})), 2)
        verify(added.accepted)
        return { workspace: workspace, manifest: added.document }
    }

    function test_plansContainedThumbnailFromVerifiedEmbeddedSource() {
        const value = fixture()
        const result = Plan.create({ assetId: "sky", role: "thumbnail" },
            value.workspace, value.manifest)
        verify(result.accepted)
        verify(!result.reused)
        compare(result.plan.sourcePath,
            "/data/drafts/draft-one/media/sky.mp4")
        verify(result.plan.relativePath.startsWith("thumbnails/sky-"))
        verify(result.plan.outputPath.startsWith(
            "/data/drafts/draft-one/thumbnails/"))
        verify(result.plan.temporaryPath.indexOf(
            ".partial-" + result.plan.fileId) > 0)
        verify(result.plan.temporaryPath.endsWith(".png"))
        compare(result.plan.sourceIdentity, hash)
        compare(result.plan.recipe, Plan.thumbnailRecipe)
    }

    function test_recipeAndRoleProduceDistinctDeterministicIdentity() {
        const value = fixture()
        const first = Plan.create({ assetId: "sky", role: "thumbnail" },
            value.workspace, value.manifest)
        const same = Plan.create({ assetId: "sky", role: "thumbnail" },
            value.workspace, value.manifest)
        const proxy = Plan.create({ assetId: "sky", role: "proxy" },
            value.workspace, value.manifest)
        compare(first.plan.derivativeIdentity, same.plan.derivativeIdentity)
        verify(first.plan.derivativeIdentity !== proxy.plan.derivativeIdentity)
        verify(proxy.plan.relativePath.startsWith("proxies/sky-"))
        verify(proxy.plan.relativePath.endsWith(".mp4"))
    }

    function test_reusesExactReadyDerivative() {
        const value = fixture()
        const planned = Plan.create({ assetId: "sky", role: "thumbnail" },
            value.workspace, value.manifest)
        const appended = Bundle.appendFile(value.manifest, {
            id: planned.plan.fileId, assetId: "sky", role: "thumbnail",
            relativePath: planned.plan.relativePath,
            originalSourcePath: "", sizeBytes: 12,
            identity: hash,
            state: "ready", error: ""
        }, 3)
        verify(appended.accepted)
        const reused = Plan.create({ assetId: "sky", role: "thumbnail" },
            value.workspace, appended.document)
        verify(reused.accepted)
        verify(reused.reused)
        compare(reused.plan.fileId, planned.plan.fileId)
        compare(reused.plan.temporaryPath, "")
    }

    function test_collisionGetsStableContainedSuffix() {
        const value = fixture()
        const planned = Plan.create({ assetId: "sky", role: "thumbnail" },
            value.workspace, value.manifest)
        const occupied = Bundle.appendFile(value.manifest, {
            id: planned.plan.fileId, assetId: "other", role: "thumbnail",
            relativePath: planned.plan.relativePath,
            originalSourcePath: "", sizeBytes: 1,
            identity: "different", state: "failed", error: "stale"
        }, 3)
        verify(occupied.accepted)
        const result = Plan.create({ assetId: "sky", role: "thumbnail" },
            value.workspace, occupied.document)
        verify(result.accepted)
        verify(result.plan.fileId.endsWith("-2"))
        verify(result.plan.relativePath.indexOf("-2.png") > 0)
    }

    function test_rejectsUnownedIncompleteAndUnsafeRequests() {
        const value = fixture()
        verify(!Plan.create({ assetId: "missing", role: "thumbnail" },
            value.workspace, value.manifest).accepted)
        verify(!Plan.create({ assetId: "sky", role: "media" },
            value.workspace, value.manifest).accepted)
        verify(!Plan.create({ assetId: "sky", role: "thumbnail",
            recipe: "unknown-recipe" }, value.workspace,
            value.manifest).accepted)
        verify(!Plan.create({ assetId: "sky", role: "thumbnail" },
            Object.assign({}, value.workspace, { rootPath: "relative/path" }),
            value.manifest).accepted)

        const incomplete = fixture({ state: "copying", identity: "" })
        verify(!Plan.create({ assetId: "sky", role: "thumbnail" },
            incomplete.workspace, incomplete.manifest).accepted)
    }
}
