import QtQuick
import QtTest
import "../../services/wallpaper/WallpaperPlaylistSchedule.js" as Schedule

TestCase {
    name: "WallpaperPlaylistSchedule"

    readonly property var entries: [
        { id: "a", path: "/a", durationMs: 1000 },
        { id: "b", path: "/b", durationMs: 2000 },
        { id: "c", path: "/c", durationMs: 3000 }
    ]

    function test_emptyIsDormant() {
        const result = Schedule.plan([], {}, 10000, 5000)
        compare(result.state, "dormant")
        compare(result.reason, "empty-playlist")
        compare(result.nextAtMs, 0)
    }

    function test_newCursorStartsFirstEntry() {
        const result = Schedule.plan(entries, {}, 10000, 5000)
        compare(result.entryId, "a")
        compare(result.startedAtMs, 10000)
        compare(result.nextAtMs, 11000)
        compare(result.advancedSteps, 0)
    }

    function test_exactBoundaryAndVariableDurations() {
        const firstBoundary = Schedule.plan(entries,
            { entryId: "a", startedAtMs: 10000 }, 11000, 5000)
        compare(firstBoundary.entryId, "b")
        compare(firstBoundary.startedAtMs, 11000)
        compare(firstBoundary.nextAtMs, 13000)

        const third = Schedule.plan(entries,
            { entryId: "a", startedAtMs: 10000 }, 13500, 5000)
        compare(third.entryId, "c")
        compare(third.startedAtMs, 13000)
        compare(third.nextAtMs, 16000)
    }

    function test_largeJumpSkipsWholeCyclesBoundedly() {
        const result = Schedule.plan(entries,
            { entryId: "a", startedAtMs: 10000 }, 6015500, 5000)
        verify(result.cyclesSkipped > 900)
        verify(result.advancedSteps > 2700)
        verify(result.nextAtMs > 6015500)
        verify(result.nextAtMs - 6015500 <= 3000)
    }

    function test_backwardClockRebasesCurrentEntry() {
        const result = Schedule.plan(entries,
            { entryId: "b", startedAtMs: 20000 }, 15000, 5000)
        compare(result.entryId, "b")
        compare(result.startedAtMs, 15000)
        compare(result.nextAtMs, 17000)
        verify(result.clockRebased)
    }

    function test_zeroDurationUsesBoundedDefault() {
        const result = Schedule.plan([
            { id: "x", path: "/x", durationMs: 0 }
        ], {}, 10000, 2500)
        compare(result.durationMs, 2500)
        compare(result.nextAtMs, 12500)
    }
}
