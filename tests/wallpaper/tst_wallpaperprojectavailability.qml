import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperProjectAvailability.js" as Availability

TestCase {
    name: "WallpaperProjectAvailability"

    function project() {
        return { schemaVersion: 1, project: {
            id: "portable", rootPath: "/project",
            assets: [
                { id: "original", kind: "static", sourcePath: "/old/a.png",
                    portablePath: "media/a.png" },
                { id: "moved", kind: "video", sourcePath: "/old/b.mp4",
                    portablePath: "media/b.mp4" },
                { id: "absent", kind: "static", sourcePath: "/gone.png" }
            ], tracks: [], markers: [], userProperties: [], outputTargets: []
        } }
    }

    function ready(path, kind) {
        return { path: path, state: "ready", kind: kind, error: "" }
    }

    function unavailable(path) {
        return { path: path, state: "failed", kind: "unsupported",
            error: "Wallpaper source is unavailable" }
    }

    function test_prefersOriginalThenSuggestsPortableFallback() {
        const records = ({})
        records["/old/a.png"] = ready("/old/a.png", "static")
        records["/old/b.mp4"] = unavailable("/old/b.mp4")
        records["/project/media/b.mp4"] = ready(
            "/project/media/b.mp4", "video")
        records["/gone.png"] = unavailable("/gone.png")
        const result = Availability.plan(project(), records)
        compare(result.state, "ready")
        compare(result.assets[0].resolvedPath, "/old/a.png")
        verify(!result.assets[0].relinkSuggested)
        compare(result.assets[1].resolvedPath, "/project/media/b.mp4")
        verify(result.assets[1].relinkSuggested)
        compare(result.assets[2].state, "missing")
        compare(result.enqueuePaths.length, 0)
    }

    function test_reportsUnsupportedAndMapsAnimatedKind() {
        const document = project()
        document.project.assets = [
            { id: "gif", sourcePath: "/a.gif" },
            { id: "bad", sourcePath: "/text.txt" }
        ]
        const records = ({
            "/a.gif": ready("/a.gif", "animatedImage"),
            "/text.txt": { state: "unsupported", kind: "unsupported",
                error: "Unsupported codec/container combination" }
        })
        const result = Availability.plan(document, records)
        compare(result.state, "ready")
        compare(result.assets[0].resolvedKind, "animated-image")
        compare(result.assets[1].state, "unsupported")
        compare(result.counts.available, 1)
        compare(result.counts.unsupported, 1)
    }

    function test_deduplicatesPendingCandidatesAndRejectsInvalidProject() {
        const document = project()
        document.project.assets[1].sourcePath = "/old/a.png"
        document.project.assets[1].portablePath = "media/a.png"
        const result = Availability.plan(document, ({}))
        compare(result.enqueuePaths.filter(path => path === "/old/a.png").length, 1)
        compare(result.enqueuePaths.filter(
            path => path === "/project/media/a.png").length, 1)
        const invalid = Availability.plan({ schemaVersion: 9 }, ({}))
        compare(invalid.state, "failed")
        verify(invalid.complete)
    }
}
