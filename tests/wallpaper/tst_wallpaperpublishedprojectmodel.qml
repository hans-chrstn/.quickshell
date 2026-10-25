import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperPublishedProjectModel.js" as Published

TestCase {
    name: "WallpaperPublishedProjectModel"

    function request() {
        const hash = "sha256:" + "a".repeat(64);
        return {
            rootPath: "/projects/Ambient",
            symlinks: [],
            projectManifest: {
                formatId: "new-shell.wallpaper-project",
                schemaVersion: 1,
                projectId: "ambient",
                savedAtMs: 10,
                projectDocument: {
                    schemaVersion: 1,
                    project: {
                        id: "ambient",
                        name: "Ambient",
                        rootPath: "",
                        assets: [
                            {
                                id: "sky",
                                name: "Sky",
                                kind: "static",
                                sourcePath: "",
                                portablePath: "media/sky.png",
                                availability: "unresolved"
                            }
                        ],
                        tracks: [],
                        markers: [],
                        userProperties: [],
                        outputTargets: []
                    }
                }
            },
            bundleManifest: {
                schemaVersion: 1,
                workspace: {
                    id: "draft-ambient",
                    projectId: "ambient",
                    state: "saved",
                    createdAtMs: 1,
                    updatedAtMs: 10,
                    revision: 1,
                    savedRevision: 1,
                    destinationPath: "/projects/Ambient",
                    lastError: "",
                    files: [
                        {
                            id: "sky",
                            assetId: "sky",
                            role: "media",
                            relativePath: "media/sky.png",
                            originalSourcePath: "/original/sky.png",
                            sizeBytes: 42,
                            identity: hash,
                            state: "ready",
                            error: ""
                        }
                    ]
                }
            },
            files: [
                {
                    relativePath: "project.json",
                    sizeBytes: 100,
                    identity: "manifest"
                },
                {
                    relativePath: "bundle.json",
                    sizeBytes: 100,
                    identity: "manifest"
                },
                {
                    relativePath: "media/sky.png",
                    sizeBytes: 42,
                    identity: hash
                }
            ]
        };
    }

    function test_acceptsAndHydratesCompleteProject() {
        const result = Published.validate(request());
        verify(result.accepted);
        compare(result.projectDocument.project.rootPath, "/projects/Ambient");
        compare(result.projectDocument.project.assets[0].sourcePath, "/projects/Ambient/media/sky.png");
    }

    function test_rejectsArbitraryOrMismatchedManifests() {
        let source = request();
        source.projectManifest.formatId = "other";
        verify(!Published.validate(source).accepted);
        source = request();
        source.bundleManifest.workspace.projectId = "different";
        verify(!Published.validate(source).accepted);
        source = request();
        source.bundleManifest.workspace.state = "draft";
        verify(!Published.validate(source).accepted);
    }

    function test_rejectsMissingExtraAndDamagedFiles() {
        let source = request();
        source.files.pop();
        verify(!Published.validate(source).accepted);
        source = request();
        source.files.push({
            relativePath: "unexpected.txt",
            sizeBytes: 1,
            identity: "x"
        });
        verify(!Published.validate(source).accepted);
        source = request();
        source.files[2].sizeBytes = 41;
        verify(!Published.validate(source).accepted);
        source = request();
        source.files[2].identity = "sha256:" + "b".repeat(64);
        verify(!Published.validate(source).accepted);
    }

    function test_rejectsSymlinkAndUnsafePortablePath() {
        let source = request();
        source.symlinks = ["media/sky.png"];
        verify(!Published.validate(source).accepted);
        source = request();
        source.projectManifest.projectDocument.project.assets[0].portablePath = "../sky.png";
        verify(!Published.validate(source).accepted);
    }

    function test_rejectsOrphanAndAmbiguousPrimaryFiles() {
        let source = request();
        const extra = Object.assign({}, source.bundleManifest.workspace.files[0], {
            id: "orphan",
            assetId: "removed",
            relativePath: "media/orphan.png"
        });
        source.bundleManifest.workspace.files.push(extra);
        source.files.push({
            relativePath: "media/orphan.png",
            sizeBytes: 42,
            identity: extra.identity
        });
        verify(!Published.validate(source).accepted);

        source = request();
        const duplicate = Object.assign({}, source.bundleManifest.workspace.files[0], {
            id: "sky-copy",
            relativePath: "media/sky-copy.png"
        });
        source.bundleManifest.workspace.files.push(duplicate);
        source.files.push({
            relativePath: "media/sky-copy.png",
            sizeBytes: 42,
            identity: duplicate.identity
        });
        verify(!Published.validate(source).accepted);
    }
}
