import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperProjectModel.js" as ProjectModel

TestCase {
    name: "WallpaperProjectModel"

    function sample() {
        return {
            schemaVersion: 1,
            project: {
                id: "ambient",
                name: " Ambient Day ",
                rootPath: "/portable/project",
                durationMs: 12000,
                assets: [
                    { id: "sky", name: "Sky", kind: "animated-image",
                        sourcePath: "file:///wallpapers/sky%20loop.webp",
                        portablePath: "media/sky loop.webp",
                        availability: "available" },
                    { id: "rain", kind: "video", sourcePath: "/moved/rain.mp4",
                        availability: "missing" }
                ],
                tracks: [{ id: "visual", type: "media", clips: [
                    { id: "intro", assetId: "sky", startMs: 0,
                        durationMs: 8000 },
                    { id: "storm", assetId: "rain", startMs: 8000,
                        durationMs: 4000, loop: true }
                ] }],
                markers: [{ id: "weather-rain", timeMs: 8000,
                    triggerType: "weather" }],
                userProperties: [{ id: "intensity", type: "number",
                    defaultValue: 0.7, group: "Weather" }],
                outputTargets: [{ id: "primary", screenName: "DP-1",
                    fit: "cover", width: 2560, height: 1440 }]
            }
        }
    }

    function test_normalizesCompleteDeclarativeProject() {
        const result = ProjectModel.parse(sample())
        verify(result.accepted)
        compare(result.document.schemaVersion, 1)
        compare(result.document.project.name, "Ambient Day")
        compare(result.document.project.rootPath, "/portable/project")
        compare(result.document.project.assets[0].sourcePath,
            "/wallpapers/sky loop.webp")
        compare(result.document.project.assets[0].portablePath,
            "media/sky loop.webp")
        compare(result.document.project.assets[1].availability, "missing")
        compare(result.document.project.tracks[0].clips[1].assetId, "rain")
        compare(result.document.project.markers[0].triggerType, "weather")
        verify(result.document.project.runtimeRequirements.animatedImages)
        verify(result.document.project.runtimeRequirements.video)
        verify(result.document.project.runtimeRequirements.triggers)
        verify(!result.document.project.runtimeRequirements.scripts)
    }

    function test_rejectsForwardVersionDuplicatesAndBrokenReferences() {
        const future = ProjectModel.parse({ schemaVersion: 2, project: {} })
        verify(!future.accepted)
        verify(future.error.indexOf("future") >= 0)

        const duplicate = sample()
        duplicate.project.assets.push({ id: "sky", sourcePath: "/other.png" })
        duplicate.project.tracks[0].clips.push({ id: "intro",
            assetId: "absent" })
        const result = ProjectModel.parse(duplicate)
        verify(!result.accepted)
        verify(result.error.indexOf("Duplicate asset id") >= 0)
        verify(result.error.indexOf("Duplicate clip id") >= 0)
        verify(result.error.indexOf("missing asset") >= 0)
    }

    function test_migratesLegacyFlatDocument() {
        const result = ProjectModel.parse({
            schemaVersion: 0,
            id: "legacy",
            name: "Legacy",
            assets: [{ id: "still", path: "/old/still.png", type: "static" }],
            tracks: [{ clips: [{ assetId: "still", durationMs: 5000 }] }],
            properties: [{ id: "caption", type: "text", defaultValue: "Hi" }],
            outputs: [{ screenName: "" }]
        })
        verify(result.accepted)
        compare(result.migratedFrom, 0)
        compare(result.document.schemaVersion, 1)
        compare(result.document.project.id, "legacy")
        compare(result.document.project.assets[0].kind, "static")
        compare(result.document.project.userProperties[0].id, "caption")
    }

    function test_relinksWithoutMutatingOriginal() {
        const original = ProjectModel.parse(sample()).document
        const result = ProjectModel.relinkAsset(original, "rain",
            "file:///new/rain%20clean.mp4", "media/rain clean.mp4")
        verify(result.accepted)
        compare(result.document.project.assets[1].sourcePath,
            "/new/rain clean.mp4")
        compare(result.document.project.assets[1].portablePath,
            "media/rain clean.mp4")
        compare(result.document.project.assets[1].availability, "unresolved")
        compare(original.project.assets[1].sourcePath, "/moved/rain.mp4")
        verify(!ProjectModel.relinkAsset(original, "absent", "/x", "x").accepted)
    }

    function test_removesOnlyUnreferencedAssetWithoutMutatingOriginal() {
        const original = ProjectModel.parse(sample()).document
        const referenced = ProjectModel.removeAsset(original, "sky")
        verify(!referenced.accepted)
        verify(referenced.error.indexOf("timeline clips") >= 0)

        original.project.tracks[0].clips = original.project.tracks[0].clips
            .filter(clip => clip.assetId !== "rain")
        const removed = ProjectModel.removeAsset(original, "rain")
        verify(removed.accepted)
        compare(removed.document.project.assets.length, 1)
        compare(removed.document.project.assets[0].id, "sky")
        compare(original.project.assets.length, 2)
        verify(!removed.document.project.runtimeRequirements.video)
        verify(!ProjectModel.removeAsset(original, "absent").accepted)
    }

    function test_rejectsOversizedCollectionsAndUnsafePaths() {
        const document = sample()
        document.project.assets = []
        for (let index = 0; index <= ProjectModel.maximumAssets; ++index)
            document.project.assets.push({ id: "asset-" + index,
                sourcePath: "/wallpapers/" + index + ".png" })
        const oversized = ProjectModel.parse(document)
        verify(!oversized.accepted)
        verify(oversized.error.indexOf("Asset limit exceeded") >= 0)

        const paths = sample()
        paths.project.assets[0].sourcePath = "relative/file.png"
        paths.project.assets[0].portablePath = "../escape.png"
        const normalized = ProjectModel.parse(paths)
        verify(normalized.accepted)
        compare(normalized.document.project.assets[0].sourcePath, "")
        compare(normalized.document.project.assets[0].portablePath, "")
    }

    function test_rejectsMalformedDocumentAndCollections() {
        verify(!ProjectModel.parse(null).accepted)
        verify(!ProjectModel.parse([]).accepted)
        const malformed = sample()
        malformed.project.assets = "not-an-array"
        malformed.project.tracks = [{ id: "broken", clips: ({}) }]
        const result = ProjectModel.parse(malformed)
        verify(!result.accepted)
        verify(result.error.indexOf("assets must be an array") >= 0)
        verify(result.error.indexOf("Track clips must be an array") >= 0)
    }
}
