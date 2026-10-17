import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperDraftPublicationValidation.js" as Validation

TestCase {
    name: "WallpaperDraftPublicationValidation"

    readonly property var document: ({
            workspace: {
                files: [
                    {
                        relativePath: "media/a.mp4",
                        sizeBytes: 42,
                        identity: "sha256:abcdef"
                    },
                    {
                        relativePath: "thumbnails/a.png",
                        sizeBytes: 7,
                        identity: "sha256:123456"
                    }
                ]
            }
        })

    function test_inventoryAcceptsExactManifest() {
        verify(Validation.acceptsInventory(document, "project.json\nbundle.json\nmedia/a.mp4\nthumbnails/a.png\n"));
    }

    function test_inventoryRejectsMissingExtraAndDuplicateFiles() {
        verify(!Validation.acceptsInventory(document, "project.json\nbundle.json\nmedia/a.mp4\n"));
        verify(!Validation.acceptsInventory(document, "project.json\nbundle.json\nmedia/a.mp4\nthumbnails/a.png\nextra"));
        verify(!Validation.acceptsInventory(document, "project.json\nbundle.json\nmedia/a.mp4\nmedia/a.mp4"));
    }

    function test_fileEvidenceMustMatchExactly() {
        const digest = "abcdef0123456789abcdef0123456789" + "abcdef0123456789abcdef0123456789";
        verify(Validation.acceptsSize(document.workspace.files[0], "42"));
        verify(!Validation.acceptsSize(document.workspace.files[0], "43"));
        const file = {
            identity: "sha256:" + digest
        };
        verify(Validation.acceptsIdentity(file, digest + "  media/a.mp4\n"));
        verify(!Validation.acceptsIdentity(file, "fedcba0123456789abcdef0123456789" + "abcdef0123456789abcdef0123456789  media/a.mp4\n"));
        verify(!Validation.acceptsIdentity(file, "not-a-hash"));
    }

    function test_publicationDocumentDropsOrphanedDraftCache() {
        const bundle = {
            workspace: {
                files: [
                    {
                        assetId: "active",
                        relativePath: "media/active.mp4"
                    },
                    {
                        assetId: "active",
                        relativePath: "thumbnails/active.png"
                    },
                    {
                        assetId: "removed",
                        relativePath: "media/removed.mp4"
                    },
                    {
                        assetId: "removed",
                        relativePath: "thumbnails/removed.png"
                    }
                ]
            }
        };
        const project = {
            project: {
                assets: [
                    {
                        id: "active"
                    }
                ]
            }
        };
        const published = Validation.publicationDocument(bundle, project);
        compare(published.workspace.files.length, 2);
        compare(published.workspace.files[0].assetId, "active");
        compare(published.workspace.files[1].assetId, "active");
        compare(bundle.workspace.files.length, 4);

        const empty = Validation.publicationDocument(bundle, {
            project: {
                assets: []
            }
        });
        compare(empty.workspace.files.length, 0);
        const excluded = Validation.excludedPaths(bundle, published);
        compare(excluded.length, 2);
        compare(excluded[0], "media/removed.mp4");
        compare(excluded[1], "thumbnails/removed.png");
    }

    function test_publicationDocumentRejectsMalformedInputs() {
        compare(Validation.publicationDocument({}, {}), null);
        compare(Validation.publicationDocument({
            workspace: {
                files: []
            }
        }, {
            project: {}
        }), null);
    }
}
