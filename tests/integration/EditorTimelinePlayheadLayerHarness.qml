import QtQuick
import QtTest
import Quickshell
import qs.editor

ShellRoot {
    id: harness

    property var viewportState: ({
            durationMs: 10000,
            viewportWidth: 500,
            minimumPixelsPerSecond: 1,
            maximumPixelsPerSecond: 800,
            pixelsPerSecond: 40,
            scrollX: 0
        })
    property int playheadMs: 1000
    property int loopStartMs: 1000
    property int loopEndMs: 5000
    property int focusRequestCount: 0
    property int scrubStartCount: 0
    property int scrubFinishCount: 0
    property int scrubCancelCount: 0
    property var scrubTimes: []
    property var loopRegions: []

    Window {
        id: window

        width: 620
        height: 180
        visible: true

        EditorTimelinePlayheadLayer {
            id: layer

            anchors.fill: parent
            viewport: harness.viewportState
            viewportOriginX: 120
            viewportWidth: 500
            playheadMs: harness.playheadMs
            loopEnabled: true
            loopStartMs: harness.loopStartMs
            loopEndMs: harness.loopEndMs
            onFocusRequested: harness.focusRequestCount += 1
            onScrubStarted: harness.scrubStartCount += 1
            onScrubTimeRequested: timeMs => {
                harness.playheadMs = timeMs;
                harness.scrubTimes = harness.scrubTimes.concat([timeMs]);
            }
            onScrubFinished: harness.scrubFinishCount += 1
            onScrubCanceled: harness.scrubCancelCount += 1
            onLoopRegionRequested: (startMs, endMs) => {
                harness.loopStartMs = startMs;
                harness.loopEndMs = endMs;
                harness.loopRegions = harness.loopRegions.concat([
                    {
                        startMs: startMs,
                        endMs: endMs
                    }
                ]);
            }
        }

        TestCase {
            name: "EditorTimelinePlayheadLayer"
            when: window.visible

            property var playhead: null
            property var playheadDrag: null
            property var loopRail: null
            property var loopStartDrag: null
            property var loopEndDrag: null

            function initTestCase() {
                playhead = findChild(layer, "timelinePlayhead");
                playheadDrag = findChild(layer, "timelinePlayheadDragArea");
                loopRail = findChild(layer, "timelineLoopRail");
                loopStartDrag = findChild(layer, "timelineLoopHandleDrag-start");
                loopEndDrag = findChild(layer, "timelineLoopHandleDrag-end");
                verify(playhead !== null);
                verify(playheadDrag !== null);
                verify(loopRail !== null);
                verify(loopStartDrag !== null);
                verify(loopEndDrag !== null);
            }

            function init() {
                harness.viewportState = {
                    durationMs: 10000,
                    viewportWidth: 500,
                    minimumPixelsPerSecond: 1,
                    maximumPixelsPerSecond: 800,
                    pixelsPerSecond: 40,
                    scrollX: 0
                };
                harness.playheadMs = 1000;
                harness.loopStartMs = 1000;
                harness.loopEndMs = 5000;
                harness.focusRequestCount = 0;
                harness.scrubStartCount = 0;
                harness.scrubFinishCount = 0;
                harness.scrubCancelCount = 0;
                harness.scrubTimes = [];
                harness.loopRegions = [];
                wait(0);
            }

            function test_playheadScrubUsesSharedViewport() {
                verify(playhead.visible);
                compare(playhead.x, 160);

                mousePress(playheadDrag, playheadDrag.width / 2, 30, Qt.LeftButton);
                mouseMove(playheadDrag, playheadDrag.width / 2 + 40, 30, 20);
                mouseRelease(playheadDrag, playheadDrag.width / 2 + 40, 30, Qt.LeftButton);

                compare(harness.focusRequestCount, 1);
                compare(harness.scrubStartCount, 1);
                compare(harness.scrubFinishCount, 1);
                compare(harness.scrubCancelCount, 0);
                verify(harness.scrubTimes.length >= 2);
                verify(harness.scrubTimes[harness.scrubTimes.length - 1] > harness.scrubTimes[0]);
            }

            function test_loopHandlesRequestBoundedRegions() {
                verify(loopRail.visible);

                mousePress(loopStartDrag, loopStartDrag.width / 2, loopStartDrag.height / 2, Qt.LeftButton);
                mouseMove(loopStartDrag, loopStartDrag.width / 2 + 20, loopStartDrag.height / 2, 20);
                mouseRelease(loopStartDrag, loopStartDrag.width / 2 + 20, loopStartDrag.height / 2, Qt.LeftButton);
                verify(harness.loopRegions.length >= 1);
                verify(harness.loopStartMs > 1000);
                compare(harness.loopEndMs, 5000);

                const previousEnd = harness.loopEndMs;
                mousePress(loopEndDrag, loopEndDrag.width / 2, loopEndDrag.height / 2, Qt.LeftButton);
                mouseMove(loopEndDrag, loopEndDrag.width / 2 - 20, loopEndDrag.height / 2, 20);
                mouseRelease(loopEndDrag, loopEndDrag.width / 2 - 20, loopEndDrag.height / 2, Qt.LeftButton);
                verify(harness.loopEndMs < previousEnd);
                verify(harness.loopEndMs > harness.loopStartMs);
                compare(harness.scrubStartCount, 2);
                compare(harness.scrubFinishCount, 2);
            }

            function test_offscreenStateHidesInteractiveGeometry() {
                harness.viewportState = Object.assign({}, harness.viewportState, {
                    scrollX: 400
                });
                wait(0);

                verify(!playhead.visible);
                verify(!loopRail.visible);
                verify(!findChild(layer, "timelineLoopHandle-start").visible);
                verify(!findChild(layer, "timelineLoopHandle-end").visible);
            }
        }
    }
}
