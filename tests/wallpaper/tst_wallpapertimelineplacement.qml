import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperTimelinePlacement.js" as Placement

TestCase {
    name: "WallpaperTimelinePlacement"

    function test_halfOpenIntervalsPermitTouchingEdges() {
        verify(!Placement.overlaps({
            startMs: 0,
            durationMs: 1000
        }, {
            startMs: 1000,
            durationMs: 500
        }));
        verify(Placement.overlaps({
            startMs: 0,
            durationMs: 1001
        }, {
            startMs: 1000,
            durationMs: 500
        }));
    }

    function test_mediaTracksRejectOverlapAndIgnoreMovingClip() {
        const track = {
            type: "media",
            clips: [
                {
                    id: "one",
                    startMs: 0,
                    durationMs: 1000
                }
            ]
        };
        const rejected = Placement.validatePlacement(track, {
            id: "two",
            startMs: 500,
            durationMs: 1000
        }, "");
        verify(!rejected.accepted);
        compare(rejected.conflictingClipId, "one");
        verify(Placement.validatePlacement(track, {
            id: "one",
            startMs: 500,
            durationMs: 1000
        }, "one").accepted);
    }

    function test_transitionTracksExplicitlyPermitOverlap() {
        const track = {
            type: "transition",
            clips: [
                {
                    id: "one",
                    startMs: 0,
                    durationMs: 1000
                }
            ]
        };
        verify(Placement.validatePlacement(track, {
            id: "two",
            startMs: 500,
            durationMs: 1000
        }, "").accepted);
    }

    function test_candidatesAreUniqueSortedEdges() {
        const result = Placement.snapCandidates([
            {
                clips: [
                    {
                        id: "one",
                        startMs: 1000,
                        durationMs: 1000
                    },
                    {
                        id: "ignored",
                        startMs: 3000,
                        durationMs: 500
                    }
                ]
            }
        ], 5000, "ignored");
        compare(JSON.stringify(result), JSON.stringify([0, 1000, 2000, 5000]));
    }

    function test_snapChoosesNearestThenEarlierCandidate() {
        let result = Placement.snapTime(1080, [1000, 1200], 100);
        verify(result.snapped);
        compare(result.timeMs, 1000);
        compare(result.deltaMs, -80);
        result = Placement.snapTime(1100, [1000, 1200], 100);
        compare(result.timeMs, 1000);
        result = Placement.snapTime(1101, [1000, 1200], 100);
        compare(result.timeMs, 1200);
    }

    function test_outsideToleranceRemainsUnsnapped() {
        const result = Placement.snapTime(1300, [1000], 100);
        verify(!result.snapped);
        compare(result.timeMs, 1300);
        compare(result.deltaMs, 0);
    }
}
