import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperPortableProjectModel.js" as Portable

TestCase {
    name: "WallpaperPortableProjectModel"

    function project() {
        return { schemaVersion: 1, project: {
            id: "ambient", name: "Ambient",
            rootPath: "/managed/draft",
            assets: [{ id: "sky", name: "Sky", kind: "static",
                sourcePath: "/managed/draft/media/sky.png",
                portablePath: "media/sky.png", availability: "available" }],
            tracks: [], markers: [], userProperties: [], outputTargets: []
        } }
    }

    function test_createsPortableIdentityWithoutMutatingSource() {
        const source = project()
        const result = Portable.create(source, 1234)
        verify(result.accepted)
        compare(result.document.formatId, Portable.formatId)
        compare(result.document.projectId, "ambient")
        compare(result.document.savedAtMs, 1234)
        compare(result.document.projectDocument.project.rootPath, "")
        compare(result.document.projectDocument.project.assets[0].sourcePath, "")
        compare(result.document.projectDocument.project.assets[0].portablePath,
            "media/sky.png")
        compare(result.document.projectDocument.project.assets[0].availability,
            "unresolved")
        compare(source.project.rootPath, "/managed/draft")
        compare(source.project.assets[0].sourcePath,
            "/managed/draft/media/sky.png")
    }

    function test_roundTripsCanonicalPortableDocument() {
        const created = Portable.create(project(), 77)
        const parsed = Portable.parse(created.document)
        verify(parsed.accepted)
        compare(parsed.document, created.document)
    }

    function test_rejectsArbitraryAndFutureDocuments() {
        verify(!Portable.parse({}).accepted)
        const created = Portable.create(project(), 1).document
        created.formatId = "some-other-project"
        verify(!Portable.parse(created).accepted)
        created.formatId = Portable.formatId
        created.schemaVersion = Portable.schemaVersion + 1
        verify(!Portable.parse(created).accepted)
    }

    function test_rejectsMismatchedIdentityAndMachinePaths() {
        const mismatch = Portable.create(project(), 1).document
        mismatch.projectId = "different"
        verify(!Portable.parse(mismatch).accepted)

        const absolute = Portable.create(project(), 1).document
        absolute.projectDocument.project.assets[0].sourcePath = "/etc/passwd"
        verify(!Portable.parse(absolute).accepted)
        absolute.projectDocument.project.assets[0].sourcePath = ""
        absolute.projectDocument.project.rootPath = "/tmp/project"
        verify(!Portable.parse(absolute).accepted)
    }

    function test_rejectsAssetsWithoutPortablePaths() {
        const source = project()
        source.project.assets[0].portablePath = ""
        verify(!Portable.create(source, 1).accepted)
    }
}
