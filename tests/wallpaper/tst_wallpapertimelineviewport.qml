import QtQuick
import QtTest
import "../../services/wallpaper/projects/WallpaperTimelineViewport.js" as Viewport

TestCase {
    name: "WallpaperTimelineViewport"

    function state() {
        return {
            durationMs: 60000,
            viewportWidth: 1000,
            pixelsPerSecond: 100,
            minimumPixelsPerSecond: 20,
            maximumPixelsPerSecond: 400,
            scrollX: 500
        };
    }

    function test_normalizesScaleContentAndScrollBounds() {
        let result = Viewport.normalize(state());
        compare(result.contentWidth, 6000);
        compare(result.maximumScrollX, 5000);
        compare(result.scrollX, 500);
        result = Viewport.normalize(Object.assign({}, state(), {
            pixelsPerSecond: 9999,
            scrollX: 99999
        }));
        compare(result.pixelsPerSecond, 400);
        compare(result.scrollX, result.maximumScrollX);
    }

    function test_timeAndPixelConversionsShareOneAuthority() {
        const viewport = Viewport.normalize(state());
        compare(Viewport.timeToContentX(viewport, 12000), 1200);
        compare(Viewport.timeToViewportX(viewport, 12000), 700);
        compare(Viewport.contentXToTime(viewport, 1200), 12000);
        compare(Viewport.viewportXToTime(viewport, 700), 12000);
    }

    function test_scrollClampsBothEdges() {
        const viewport = Viewport.normalize(state());
        compare(Viewport.scrollBy(viewport, -5000).scrollX, 0);
        compare(Viewport.scrollBy(viewport, 9000).scrollX, viewport.maximumScrollX);
    }

    function test_zoomPreservesTimeUnderCursor() {
        const before = Viewport.normalize(state());
        const anchorX = 300;
        const anchorTime = Viewport.viewportXToTime(before, anchorX);
        const after = Viewport.zoomAround(before, 200, anchorX);
        compare(after.pixelsPerSecond, 200);
        compare(Viewport.viewportXToTime(after, anchorX), anchorTime);
    }

    function test_zoomAtBoundaryRemainsBounded() {
        const before = Viewport.normalize(Object.assign({}, state(), {
            scrollX: 0
        }));
        const after = Viewport.zoomAround(before, 400, 0);
        compare(after.scrollX, 0);
        compare(Viewport.viewportXToTime(after, 0), 0);
    }

    function test_visibleRangeIncludesBoundedOverscan() {
        const viewport = Viewport.normalize(state());
        const range = Viewport.visibleRange(viewport, 100);
        compare(range.startMs, 4000);
        compare(range.endMs, 16000);
    }

    function test_virtualizesByHalfOpenClipBounds() {
        const clips = [
            {
                id: "before",
                startMs: 0,
                durationMs: 4000
            },
            {
                id: "touching",
                startMs: 4000,
                durationMs: 1000
            },
            {
                id: "visible",
                startMs: 6000,
                durationMs: 2000
            },
            {
                id: "edge",
                startMs: 15000,
                durationMs: 1000
            },
            {
                id: "after",
                startMs: 16000,
                durationMs: 1000
            }
        ];
        const visible = Viewport.visibleClips(clips, Viewport.normalize(state()), 100);
        compare(visible.length, 3);
        compare(visible[0].id, "touching");
        compare(visible[1].id, "visible");
        compare(visible[2].id, "edge");
    }

    function test_virtualizesQmlStyleArrayLikeCollections() {
        const state = Viewport.normalize({
            durationMs: 10000,
            viewportWidth: 500,
            pixelsPerSecond: 100,
            scrollX: 0
        });
        const collection = {
            0: {
                id: "visible",
                startMs: 0,
                durationMs: 1000
            },
            1: {
                id: "outside",
                startMs: 8000,
                durationMs: 1000
            },
            length: 2
        };
        const visible = Viewport.visibleClips(collection, state, 0);
        compare(visible.length, 1);
        compare(visible[0].id, "visible");
    }

    function test_shortTimelineDoesNotInventScrollableSpace() {
        const result = Viewport.normalize({
            durationMs: 1000,
            viewportWidth: 800,
            pixelsPerSecond: 100,
            minimumPixelsPerSecond: 20,
            maximumPixelsPerSecond: 400,
            scrollX: 100
        });
        compare(result.contentWidth, 800);
        compare(result.maximumScrollX, 0);
        compare(result.scrollX, 0);
        compare(Viewport.viewportXToTime(result, 700), 1000);
    }
}
