import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperTimelineGesture.js" as Gesture
import "../../services/wallpaper/projects/WallpaperTimelineGestureSession.js" as Session

TestCase {
    name: "WallpaperTimelineGestureSession"

    function gesture(id) {
        return Gesture.begin({
            gestureId: id,
            mode: "move",
            clip: {
                id: "clip",
                startMs: 1000,
                durationMs: 2000
            },
            trackId: "visual",
            pointerStartX: 0,
            pixelsPerSecond: 100,
            snapTolerancePx: 8,
            projectDurationMs: 10000,
            sourceDurationMs: 4000
        }).gesture;
    }

    function test_beginsOnlyOneGesture() {
        const first = Session.begin(Session.idle(""), gesture("one"));
        verify(first.accepted);
        verify(first.state.active);
        verify(!Session.begin(first.state, gesture("two")).accepted);
    }

    function test_updateRejectsForeignPreview() {
        const active = Session.begin(Session.idle(""), gesture("one")).state;
        const foreign = Gesture.preview(gesture("two"), 100, [], false);
        verify(!Session.update(active, foreign).accepted);
        compare(active.preview, null);
    }

    function test_finishRequiresPreviewAndReturnsSingleCommand() {
        const active = Session.begin(Session.idle(""), gesture("one")).state;
        verify(!Session.finish(active).accepted);
        const preview = Gesture.preview(active.gesture, 150, [], false);
        const updated = Session.update(active, preview);
        verify(updated.accepted);
        const finished = Session.finish(updated.state);
        verify(finished.accepted);
        compare(finished.command.type, "move-clip");
        compare(finished.command.startMs, 2500);
        verify(!finished.state.active);
        compare(finished.state.completedGestureId, "one");
        verify(!Session.finish(finished.state).accepted);
    }

    function test_completedIdentityCannotRestartImmediately() {
        const completed = Session.idle("one");
        verify(!Session.begin(completed, gesture("one")).accepted);
        verify(Session.begin(completed, gesture("two")).accepted);
    }

    function test_cancelDropsPreviewWithoutCommand() {
        let state = Session.begin(Session.idle("older"), gesture("one")).state;
        state = Session.update(state, Gesture.preview(state.gesture, 100, [], false)).state;
        const canceled = Session.cancel(state);
        verify(canceled.accepted);
        compare(canceled.command, null);
        verify(!canceled.state.active);
        compare(canceled.state.completedGestureId, "older");
    }

    function test_idleCancelIsIdempotent() {
        const state = Session.idle("done");
        const canceled = Session.cancel(state);
        verify(canceled.accepted);
        compare(canceled.state, state);
    }
}
