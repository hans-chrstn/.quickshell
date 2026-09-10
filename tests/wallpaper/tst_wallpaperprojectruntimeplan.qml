import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperProjectRuntimePlan.js" as RuntimePlan

TestCase {
    name: "WallpaperProjectRuntimePlan"

    function project() {
        return { schemaVersion: 1, project: {
            id: "runtime", name: "Runtime", durationMs: 0,
            assets: [
                { id: "still", kind: "static", sourcePath: "/still.png" },
                { id: "motion", kind: "video", sourcePath: "/motion.mp4" }
            ], tracks: [
                { id: "back", type: "media", clips: [
                    { id: "later", assetId: "motion", startMs: 1000,
                        durationMs: 2000 }
                ] },
                { id: "front", type: "media", clips: [
                    { id: "first", assetId: "still", startMs: 0,
                        durationMs: 2000 }
                ] },
                { id: "ignored", type: "audio", clips: [
                    { id: "audio", assetId: "motion", durationMs: 9000 }
                ] }
            ], markers: [], userProperties: [], outputTargets: [
                { id: "all", screenName: "", fit: "contain" },
                { id: "primary", screenName: "DP-1", fit: "stretch" }
            ]
        } }
    }

    function availability() {
        return { projectId: "runtime", complete: true, assets: [
            { assetId: "still", state: "available",
                resolvedPath: "/still.png", media: {
                    state: "ready", kind: "static", codec: "png" } },
            { assetId: "motion", state: "available",
                resolvedPath: "/motion.mp4", media: {
                    state: "ready", kind: "video", codec: "h264" } }
        ] }
    }

    function test_buildsRendererCompatiblePlanAndDerivesDuration() {
        const result = RuntimePlan.build(project(), availability())
        verify(result.accepted)
        verify(result.plan.ready)
        compare(result.plan.durationMs, 3000)
        compare(result.plan.clips.length, 2)
        compare(result.plan.clips[0].id, "first")
        compare(result.plan.clips[0].backend, "static")
        compare(result.plan.clips[1].backend, "video")
        compare(result.plan.outputTargets[0].fit, "contain")
        compare(RuntimePlan.frameAt(result.plan, 1500).length, 2)
        compare(RuntimePlan.frameAt(result.plan, 2500)[0].id, "later")
        compare(RuntimePlan.frameAt(result.plan, 3000).length, 0)
        compare(RuntimePlan.frameForScreen(
            result.plan, 1500, "DP-1")[0].fit, "stretch")
        compare(RuntimePlan.frameForScreen(
            result.plan, 1500, "HDMI-A-1")[0].fit, "contain")
        compare(RuntimePlan.outputForScreen(
            result.plan, "missing").id, "all")
    }

    function test_blocksUnavailableAndUnsupportedClips() {
        const diagnostic = availability()
        diagnostic.assets[0] = { assetId: "still", state: "missing",
            error: "gone" }
        diagnostic.assets[1].media.kind = "animatedImage"
        diagnostic.assets[1].media.codec = "webp"
        const result = RuntimePlan.build(project(), diagnostic)
        verify(result.accepted)
        verify(!result.plan.ready)
        compare(result.plan.clips.length, 0)
        compare(result.plan.blockedClips.length, 2)
        compare(result.plan.assets[0].state, "missing")
        compare(result.plan.assets[1].state, "unsupported")
    }

    function test_rejectsMismatchedAndInvalidInputs() {
        const mismatch = availability()
        mismatch.projectId = "other"
        verify(!RuntimePlan.build(project(), mismatch).accepted)
        verify(!RuntimePlan.build({ schemaVersion: 8 }, availability()).accepted)
        compare(RuntimePlan.frameAt(null, 0).length, 0)
    }

    function test_declaredDurationClipsTimelineExactly() {
        const document = project()
        document.project.durationMs = 1500
        const result = RuntimePlan.build(document, availability())
        verify(result.accepted)
        compare(result.plan.durationMs, 1500)
        compare(result.plan.clips[1].durationMs, 500)
        compare(RuntimePlan.frameAt(result.plan, 1499).length, 2)
        compare(RuntimePlan.frameAt(result.plan, 1500).length, 0)
    }
}
