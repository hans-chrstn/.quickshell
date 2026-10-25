import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperTimelineRuler.js" as Ruler

TestCase {
    name: "WallpaperTimelineRuler"

    function viewport(pixelsPerSecond) {
        return {
            durationMs: 120000,
            viewportWidth: 800,
            pixelsPerSecond: pixelsPerSecond,
            minimumPixelsPerSecond: 10,
            maximumPixelsPerSecond: 1000,
            scrollX: 0
        };
    }

    function test_policyAdaptsDensityToZoom() {
        const zoomedOut = Ruler.policy(viewport(20), 12, 64, 512);
        const zoomedIn = Ruler.policy(viewport(400), 12, 64, 512);
        verify(zoomedOut.minorIntervalMs > zoomedIn.minorIntervalMs);
        verify(zoomedOut.majorIntervalMs > zoomedIn.majorIntervalMs);
        verify(zoomedOut.minorSpacingPx >= 12);
        verify(zoomedIn.minorSpacingPx >= 12);
        compare(zoomedOut.majorIntervalMs % zoomedOut.minorIntervalMs, 0);
        compare(zoomedIn.majorIntervalMs % zoomedIn.minorIntervalMs, 0);
    }

    function test_generatesBoundedSortedTicks() {
        const result = Ruler.ticks(viewport(100), 100, 10, 60, 32);
        verify(result.ticks.length > 0);
        verify(result.ticks.length <= 32);
        for (let index = 1; index < result.ticks.length; ++index) {
            verify(result.ticks[index].timeMs > result.ticks[index - 1].timeMs);
            verify(result.ticks[index].x > result.ticks[index - 1].x);
        }
    }

    function test_majorTicksOwnLabelsOnly() {
        const result = Ruler.ticks(viewport(100), 0, 10, 60, 64);
        verify(result.ticks.some(tick => tick.major));
        for (const tick of result.ticks)
            compare(tick.label.length > 0, tick.major);
    }

    function test_formatsSubsecondMinuteHourAndDayLabels() {
        compare(Ruler.label(250, 100), "0.3s");
        compare(Ruler.label(65000, 5000), "1:05");
        compare(Ruler.label(3723000, 60000), "1:02:03");
        compare(Ruler.label(93784000, 3600000), "1d 02:03:04");
    }

    function test_scrolledRulerUsesViewportCoordinates() {
        const state = viewport(100);
        state.scrollX = 1000;
        const result = Ruler.ticks(state, 0, 10, 60, 64);
        verify(result.ticks.length > 0);
        verify(result.ticks[0].x >= 0);
        verify(result.ticks[result.ticks.length - 1].x <= 800);
    }

    function test_playheadClampsAndReportsVisibility() {
        let result = Ruler.playhead(viewport(100), -100);
        compare(result.timeMs, 0);
        verify(result.visible);
        const state = viewport(100);
        state.scrollX = 1000;
        result = Ruler.playhead(state, 5000);
        compare(result.x, -500);
        verify(!result.visible);
        result = Ruler.playhead(state, 999999);
        compare(result.timeMs, 120000);
    }

    function test_invalidInputsRemainFinite() {
        const result = Ruler.ticks({
            durationMs: 0,
            viewportWidth: 0,
            pixelsPerSecond: 0
        }, -10, -1, -1, 0);
        verify(result.ticks.length <= result.policy.maximumTicks);
        verify(Number.isFinite(result.policy.minorSpacingPx));
        verify(Number.isFinite(result.policy.majorSpacingPx));
    }
}
