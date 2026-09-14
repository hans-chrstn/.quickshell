import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperTimelineGesture.js" as Gesture

TestCase {
    name: "WallpaperTimelineGesture"

    function options(mode) {
        return {
            gestureId: "gesture-1",
            mode: mode,
            clip: {
                id: "clip-1",
                startMs: 2000,
                durationMs: 4000,
                sourceInMs: 0,
                loop: false
            },
            trackId: "visual",
            pointerStartX: 100,
            pixelsPerSecond: 100,
            snapTolerancePx: 10,
            projectDurationMs: 12000,
            sourceDurationMs: 8000
        };
    }

    function test_rejectsInvalidGestureBoundary() {
        verify(!Gesture.begin({
            mode: "paint",
            clip: {
                id: "clip"
            },
            pixelsPerSecond: 100
        }).accepted);
        verify(!Gesture.begin({
            mode: "move",
            clip: {
                id: "clip"
            },
            trackId: "track",
            pixelsPerSecond: 0
        }).accepted);
        verify(!Gesture.begin({
            mode: "move",
            clip: {},
            trackId: "track",
            pixelsPerSecond: 100
        }).accepted);
        const missingIdentity = options("move");
        missingIdentity.gestureId = "";
        verify(!Gesture.begin(missingIdentity).accepted);
    }

    function test_movePreviewUsesTimeNotPixels() {
        const first = Gesture.begin(options("move")).gesture;
        const firstPreview = Gesture.preview(first, 250, [], false).preview;
        compare(firstPreview.timing.startMs, 3500);

        const zoomedOptions = options("move");
        zoomedOptions.pixelsPerSecond = 200;
        const zoomed = Gesture.begin(zoomedOptions).gesture;
        const zoomedPreview = Gesture.preview(zoomed, 400, [], false).preview;
        compare(zoomedPreview.timing.startMs, 3500);
    }

    function test_moveSnapsEitherEdgeAndClampsProject() {
        const gesture = Gesture.begin(options("move")).gesture;
        let preview = Gesture.preview(gesture, 195, [3000], true).preview;
        verify(preview.snapped);
        compare(preview.timing.startMs, 3000);
        preview = Gesture.preview(gesture, 2000, [], false).preview;
        compare(preview.timing.startMs, 8000);
    }

    function test_trimAndResizePreviewRemainTemporary() {
        const trim = Gesture.begin(options("trim-start")).gesture;
        const trimmed = Gesture.preview(trim, 300, [], false).preview;
        compare(trimmed.timing.startMs, 4000);
        compare(trimmed.timing.durationMs, 2000);
        compare(trimmed.timing.sourceInMs, 2000);
        compare(trim.original.startMs, 2000);

        const resize = Gesture.begin(options("resize-end")).gesture;
        const resized = Gesture.preview(resize, 500, [], false).preview;
        compare(resized.timing.durationMs, 8000);
        compare(resize.original.durationMs, 4000);
    }

    function test_pixelToleranceScalesWithZoom() {
        let settings = options("move");
        let gesture = Gesture.begin(settings).gesture;
        verify(Gesture.preview(gesture, 109, [2100], true).preview.snapped);
        settings = options("move");
        settings.pixelsPerSecond = 200;
        gesture = Gesture.begin(settings).gesture;
        verify(!Gesture.preview(gesture, 109, [2100], true).preview.snapped);
    }

    function test_finishProducesOneSemanticCommand() {
        const gesture = Gesture.begin(options("move")).gesture;
        const preview = Gesture.preview(gesture, 250, [], false);
        const result = Gesture.finish(gesture, preview);
        verify(result.accepted);
        compare(result.command.type, "move-clip");
        compare(result.command.clipId, "clip-1");
        compare(result.command.trackId, "visual");
        compare(result.command.startMs, 3500);
    }

    function test_finishRejectsStaleOrForeignPreview() {
        const gesture = Gesture.begin(options("move")).gesture;
        const preview = Gesture.preview(gesture, 250, [], false).preview;
        preview.gestureId = "older-gesture";
        verify(!Gesture.finish(gesture, preview).accepted);
        verify(!Gesture.finish(gesture, null).accepted);
    }

    function test_finishPreservesLoopResizeIntent() {
        const settings = options("resize-end");
        settings.clip.loop = true;
        const gesture = Gesture.begin(settings).gesture;
        const preview = Gesture.preview(gesture, 700, [], false);
        const result = Gesture.finish(gesture, preview);
        verify(result.accepted);
        compare(result.command.type, "resize-clip-end");
        compare(result.command.endMs, 12000);
        verify(result.command.loop);
    }
}
