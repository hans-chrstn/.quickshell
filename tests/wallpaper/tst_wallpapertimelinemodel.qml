import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperTimelineModel.js" as Timeline

TestCase {
    name: "WallpaperTimelineModel"

    function test_normalizesFiniteClipAgainstSourceAndProject() {
        const timing = Timeline.normalizeTiming({
            startMs: 9000,
            durationMs: 8000,
            sourceInMs: 2000
        }, 6000, 12000);
        compare(timing.startMs, 9000);
        compare(timing.durationMs, 3000);
        compare(timing.sourceInMs, 2000);
        verify(!timing.loop);
    }

    function test_loopMayExtendWithoutDuplicatingRecords() {
        const timing = Timeline.normalizeTiming({
            startMs: 1000,
            durationMs: 20000,
            sourceInMs: 2000,
            loop: true
        }, 5000, 18000);
        compare(timing.durationMs, 17000);
        compare(Timeline.sourceTimeAt(timing, 1000), 2000);
        compare(Timeline.sourceTimeAt(timing, 4000), 2000);
        compare(Timeline.sourceTimeAt(timing, 5500), 3500);
    }

    function test_finiteResizeStopsAtSourceEnd() {
        const timing = {
            startMs: 2000,
            durationMs: 2000,
            sourceInMs: 1000,
            sourceDurationMs: 5000,
            loop: false
        };
        const resized = Timeline.resizeEnd(timing, 12000, 20000);
        compare(resized.durationMs, 4000);
        compare(Timeline.endMs(resized), 6000);
    }

    function test_loopResizeStopsOnlyAtProjectEnd() {
        const timing = {
            startMs: 2000,
            durationMs: 2000,
            sourceInMs: 1000,
            sourceDurationMs: 5000,
            loop: true
        };
        const resized = Timeline.resizeEnd(timing, 12000, 10000);
        compare(resized.durationMs, 8000);
        compare(Timeline.endMs(resized), 10000);
    }

    function test_trimStartPreservesVisibleSourcePhase() {
        const timing = {
            startMs: 1000,
            durationMs: 7000,
            sourceInMs: 1000,
            sourceDurationMs: 5000,
            loop: true
        };
        const trimmed = Timeline.trimStart(timing, 3500, 12000);
        compare(trimmed.startMs, 3500);
        compare(trimmed.durationMs, 4500);
        compare(trimmed.sourceInMs, 3500);
    }

    function test_dropRequiresCompatibleEditableTrackAndStableId() {
        const track = {
            id: "visual",
            type: "media",
            enabled: true
        };
        const asset = {
            id: "rain",
            kind: "video"
        };
        const accepted = Timeline.planDrop(track, asset, 9000, 6000, 12000, "rain-clip");
        verify(accepted.accepted);
        compare(accepted.clip.startMs, 9000);
        compare(accepted.clip.durationMs, 3000);
        verify(!Timeline.planDrop(Object.assign({}, track, {
            locked: true
        }), asset, 0, 6000, 12000, "locked").accepted);
        verify(!Timeline.planDrop(track, {
            id: "sound",
            kind: "audio"
        }, 0, 6000, 12000, "wrong-track").accepted);
        verify(!Timeline.planDrop(track, asset, 0, 6000, 12000, "").accepted);
    }

    function test_staticAssetGetsBoundedDefaultDuration() {
        const result = Timeline.planDrop({
            id: "visual",
            type: "media"
        }, {
            id: "still",
            kind: "static"
        }, 8000, 0, 10000, "still-1");
        verify(result.accepted);
        compare(result.clip.durationMs, 2000);
    }
}
