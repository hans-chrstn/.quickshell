import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperDraftSavePlan.js" as SavePlan
import "../../services/wallpaper/projects/WallpaperProjectBundleModel.js" as Bundle

TestCase {
    name: "WallpaperDraftSavePlan"

    function fixture(fileState) {
        const entry = { id: "draft-one", projectId: "project-one",
            rootPath: "/managed/draft-one" }
        let manifest = Bundle.create(entry.id, entry.projectId, 1)
        const appended = Bundle.appendFile(manifest, {
            id: "sky", assetId: "sky", role: "media",
            relativePath: "media/sky.png",
            originalSourcePath: "/original/sky.png", sizeBytes: 42,
            identity: "sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
            state: fileState || "ready", error: ""
        }, 2)
        verify(appended.accepted)
        return { entry: entry, manifest: appended.document }
    }

    function test_buildsDestinationLocalStagingPlan() {
        const value = fixture()
        const result = SavePlan.create({ parentPath: "/home/user/Wallpapers/",
            folderName: " Rainy Evening ", operationId: "save-17" },
            value.entry, value.manifest, 100)
        verify(result.accepted)
        compare(result.plan.parentPath, "/home/user/Wallpapers")
        compare(result.plan.folderName, "Rainy Evening")
        compare(result.plan.destinationPath,
            "/home/user/Wallpapers/Rainy Evening")
        compare(result.plan.stagingPath,
            "/home/user/Wallpapers/.Rainy Evening.saving-save-17")
        compare(result.plan.publicationStrategy,
            "destination-local-copy-then-rename")
        compare(result.plan.savingDocument.workspace.state, "saving")
        compare(result.plan.savingDocument.workspace.destinationPath,
            result.plan.destinationPath)
    }

    function test_keepsFolderAndProjectIdentitySeparate() {
        const value = fixture()
        const result = SavePlan.create({ parentPath: "/exports",
            folderName: "Filesystem Name", operationId: "save" },
            value.entry, value.manifest, 100)
        verify(result.accepted)
        compare(result.plan.projectId, "project-one")
        compare(result.plan.folderName, "Filesystem Name")
        compare(value.manifest.workspace.destinationPath, "")
        compare(value.manifest.workspace.state, "draft")
    }

    function test_rejectsUnsafeAndHiddenFolderNames() {
        const value = fixture()
        for (const name of ["", ".", "..", ".hidden", "a/b", "a\\b",
                "bad\nname"])
            verify(!SavePlan.create({ parentPath: "/exports",
                folderName: name, operationId: "save" }, value.entry,
                value.manifest, 100).accepted, name)
        verify(!SavePlan.create({ parentPath: "/exports",
            folderName: "x".repeat(SavePlan.maximumFolderNameLength + 1),
            operationId: "save" }, value.entry, value.manifest, 100).accepted)
    }

    function test_rejectsRelativeParentIncompleteBundleAndIdentityMismatch() {
        const value = fixture()
        verify(!SavePlan.create({ parentPath: "relative/path",
            folderName: "Project", operationId: "save" }, value.entry,
            value.manifest, 100).accepted)
        verify(!SavePlan.create({ parentPath: "/exports",
            folderName: "Project", operationId: "" }, value.entry,
            value.manifest, 100).accepted)
        const incomplete = fixture("copying")
        verify(!SavePlan.create({ parentPath: "/exports",
            folderName: "Project", operationId: "save" }, incomplete.entry,
            incomplete.manifest, 100).accepted)
        verify(!SavePlan.create({ parentPath: "/exports",
            folderName: "Project", operationId: "save" },
            Object.assign({}, value.entry, { projectId: "other" }),
            value.manifest, 100).accepted)
    }
}
