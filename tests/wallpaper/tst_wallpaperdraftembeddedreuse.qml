import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperDraftEmbeddedReuse.js" as Reuse
import "../../services/wallpaper/projects/WallpaperProjectBundleModel.js" as Bundle

TestCase {
    name: "WallpaperDraftEmbeddedReuse"

    readonly property string identity:
        "sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

    function fixture(fileChanges, assets) {
        const workspace = { id: "draft-one", projectId: "project-one",
            rootPath: "/drafts/draft-one" }
        let manifest = Bundle.create("draft-one", "project-one", 1)
        const appended = Bundle.appendFile(manifest, Object.assign({
            id: "movie", assetId: "movie", role: "media",
            relativePath: "media/movie.mp4",
            originalSourcePath: "/original/movie.mp4", sizeBytes: 100,
            identity: identity, state: "ready", error: ""
        }, fileChanges || ({})), 2)
        verify(appended.accepted)
        return { workspace: workspace, manifest: appended.document,
            project: { schemaVersion: 1, project: { id: "project-one",
                name: "Project", assets: assets || [], tracks: [], markers: [],
                userProperties: [], outputTargets: [] } } }
    }

    function test_resolvesReadyManagedCopyWithoutMutation() {
        const value = fixture()
        const result = Reuse.resolve({ assetId: "movie", name: "Movie",
            sourcePath: "/original/movie.mp4" }, value.workspace,
            value.manifest, value.project)
        verify(result.accepted)
        verify(result.found)
        compare(result.asset.sourcePath,
            "/drafts/draft-one/media/movie.mp4")
        compare(result.asset.portablePath, "media/movie.mp4")
        verify(result.asset.reused)
        compare(value.project.project.assets.length, 0)
        compare(value.manifest.workspace.files.length, 1)
    }

    function test_reportsNoMatchWithoutTreatingItAsFailure() {
        const value = fixture()
        const result = Reuse.resolve({ assetId: "other", name: "Other",
            sourcePath: "/original/other.mp4" }, value.workspace,
            value.manifest, value.project)
        verify(result.accepted)
        verify(!result.found)
    }

    function test_rejectsIdentityConflictAndExistingAttachment() {
        const value = fixture()
        const conflict = Reuse.resolve({ assetId: "movie-2",
            sourcePath: "/original/movie.mp4" }, value.workspace,
            value.manifest, value.project)
        verify(!conflict.accepted)
        verify(conflict.found)
        verify(conflict.error.indexOf("conflicts") >= 0)

        const attached = fixture(null, [{ id: "movie", name: "Movie",
            kind: "video", sourcePath: "/drafts/draft-one/media/movie.mp4",
            portablePath: "media/movie.mp4", availability: "available" }])
        const duplicate = Reuse.resolve({ assetId: "movie",
            sourcePath: "/original/movie.mp4" }, attached.workspace,
            attached.manifest, attached.project)
        verify(!duplicate.accepted)
        verify(duplicate.error.indexOf("already attached") >= 0)
    }

    function test_rejectsIncompleteIdentityAndMalformedOwnership() {
        const incomplete = fixture({ identity: "", state: "ready" })
        const missingIdentity = Reuse.resolve({ assetId: "movie",
            sourcePath: "/original/movie.mp4" }, incomplete.workspace,
            incomplete.manifest, incomplete.project)
        verify(!missingIdentity.accepted)
        verify(missingIdentity.found)

        const value = fixture()
        const wrongWorkspace = Object.assign({}, value.workspace,
            { id: "other" })
        verify(!Reuse.resolve({ assetId: "movie",
            sourcePath: "/original/movie.mp4" }, wrongWorkspace,
            value.manifest, value.project).accepted)
    }
}
