import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperTimelineLoop.js" as Loop

TestCase {
    name: "WallpaperTimelineLoop"

    function loop(values) {
        return Object.assign({ durationMs: 10000, startMs: 2000,
            endMs: 8000, minimumSpanMs: 100, enabled: false }, values || {})
    }

    function test_normalizesBoundsAndMinimumSpan() {
        const result = Loop.normalize({ durationMs: 1000, startMs: 900,
            endMs: 100, minimumSpanMs: 200 })
        compare(result.startMs, 800)
        compare(result.endMs, 1000)
        verify(!result.enabled)
    }

    function test_startCannotCrossEndOrMinimumSpan() {
        const result = Loop.moveStart(loop(), 7999)
        compare(result.startMs, 7900)
        compare(result.endMs, 8000)
    }

    function test_endCannotCrossStartOrDuration() {
        const result = Loop.moveEnd(loop(), 0)
        compare(result.startMs, 2000)
        compare(result.endMs, 2100)
        compare(Loop.moveEnd(loop(), 99999).endMs, 10000)
    }

    function test_toggleRequiresValidSpan() {
        verify(Loop.setEnabled(loop(), true).enabled)
        verify(!Loop.setEnabled({ durationMs: 50, startMs: 0,
            endMs: 20, minimumSpanMs: 30 }, true).enabled)
    }

    function test_containsUsesHalfOpenRange() {
        verify(Loop.contains(loop(), 2000))
        verify(Loop.contains(loop(), 7999))
        verify(!Loop.contains(loop(), 8000))
    }

    function test_operationsDoNotMutateInput() {
        const original = loop()
        Loop.moveStart(original, 3000)
        compare(original.startMs, 2000)
        verify(Loop.setEnabled(original, true).enabled)
        verify(!original.enabled)
    }
}
