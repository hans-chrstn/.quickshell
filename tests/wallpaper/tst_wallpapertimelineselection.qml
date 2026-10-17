import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperTimelineSelection.js" as Selection

TestCase {
    name: "WallpaperTimelineSelection"

    function tracks() {
        return [
            {
                id: "front",
                clips: [
                    {
                        id: "b",
                        startMs: 3000,
                        durationMs: 1000
                    },
                    {
                        id: "a",
                        startMs: 1000,
                        durationMs: 1000
                    },
                    {
                        id: "c",
                        startMs: 5000,
                        durationMs: 1000
                    }
                ]
            },
            {
                id: "empty",
                clips: []
            },
            {
                id: "back",
                clips: [
                    {
                        id: "near",
                        startMs: 3200,
                        durationMs: 1000
                    },
                    {
                        id: "far",
                        startMs: 9000,
                        durationMs: 1000
                    }
                ]
            }
        ];
    }

    function test_replaceAndCanonicalOrdering() {
        let state = Selection.selectClip(Selection.empty(""), tracks(), "front", "b", "replace");
        compare(state.primaryClipId, "b");
        state = Selection.selectClip(state, tracks(), "front", "a", "add");
        compare(JSON.stringify(state.clipIds), JSON.stringify(["a", "b"]));
    }

    function test_toggleAddsAndRemovesWithoutDuplicates() {
        let state = Selection.selectClip(Selection.empty(""), tracks(), "front", "a", "toggle");
        compare(state.clipIds.length, 1);
        state = Selection.selectClip(state, tracks(), "front", "a", "toggle");
        compare(state.clipIds.length, 0);
        compare(state.primaryClipId, "");
    }

    function test_rangeUsesStableTrackOrder() {
        let state = Selection.selectClip(Selection.empty(""), tracks(), "front", "a", "replace");
        state = Selection.selectClip(state, tracks(), "front", "c", "range");
        compare(JSON.stringify(state.clipIds), JSON.stringify(["a", "b", "c"]));
        compare(state.anchorClipId, "a");
        compare(state.primaryClipId, "c");
    }

    function test_crossTrackRangeStartsNewAnchor() {
        let state = Selection.selectClip(Selection.empty(""), tracks(), "front", "a", "replace");
        state = Selection.selectClip(state, tracks(), "back", "near", "range");
        compare(JSON.stringify(state.clipIds), JSON.stringify(["near"]));
        compare(state.trackId, "back");
    }

    function test_normalizeDropsDeletedIdsDefensively() {
        const state = Selection.normalize({
            trackId: "front",
            primaryClipId: "missing",
            anchorClipId: "a",
            clipIds: ["missing", "b", "a", "a"]
        }, tracks());
        compare(JSON.stringify(state.clipIds), JSON.stringify(["a", "b"]));
        compare(state.primaryClipId, "a");
    }

    function test_horizontalFocusAndRangeExtension() {
        let state = Selection.selectClip(Selection.empty("front"), tracks(), "front", "a", "replace");
        state = Selection.focusHorizontal(state, tracks(), 1, false);
        compare(state.primaryClipId, "b");
        state = Selection.focusHorizontal(state, tracks(), 1, true);
        compare(JSON.stringify(state.clipIds), JSON.stringify(["b", "c"]));
    }

    function test_verticalFocusSkipsEmptyAndChoosesNearestTime() {
        let state = Selection.selectClip(Selection.empty("front"), tracks(), "front", "b", "replace");
        state = Selection.focusVertical(state, tracks(), 1);
        compare(state.trackId, "back");
        compare(state.primaryClipId, "near");
        state = Selection.focusVertical(state, tracks(), -1);
        compare(state.trackId, "front");
        compare(state.primaryClipId, "b");
    }

    function test_trackSelectionClearsClips() {
        let state = Selection.selectClip(Selection.empty("front"), tracks(), "front", "a", "replace");
        state = Selection.selectTrack(state, tracks(), "back");
        compare(state.trackId, "back");
        compare(state.clipIds.length, 0);
    }

    function test_semanticCommandsUseDefensiveSelection() {
        const state = {
            trackId: "front",
            primaryClipId: "b",
            anchorClipId: "a",
            clipIds: ["b", "a", "deleted"]
        };
        let result = Selection.command(state, tracks(), "remove", {});
        verify(result.accepted);
        compare(JSON.stringify(result.command.clipIds), JSON.stringify(["a", "b"]));
        result.command.clipIds.push("mutated");
        compare(state.clipIds.length, 3);
        result = Selection.command(state, tracks(), "nudge", {
            deltaMs: 50
        });
        compare(result.command.deltaMs, 50);
        verify(!Selection.command(state, tracks(), "nudge", {
            deltaMs: 0
        }).accepted);
        result = Selection.command(state, tracks(), "split", {
            timeMs: 3500
        });
        compare(result.command.timeMs, 3500);
    }

    function test_emptyAndUnsupportedCommandsFailClosed() {
        verify(!Selection.command(Selection.empty(""), tracks(), "remove", {}).accepted);
        const selected = Selection.selectClip(Selection.empty(""), tracks(), "front", "a", "replace");
        verify(!Selection.command(selected, tracks(), "paint", {}).accepted);
    }
}
