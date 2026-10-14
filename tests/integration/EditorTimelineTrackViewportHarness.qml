import QtQuick
import QtTest
import Quickshell
import qs.editor

ShellRoot {
    id: harness

    property int focusRequestCount: 0
    property string selectedTrackId: ""
    property string selectedClipId: ""
    property string selectedMode: ""
    property int playheadTimeMs: -1
    property string contextTrackId: ""
    property string contextClipId: ""
    property int gestureStartCount: 0
    property int gestureMoveCount: 0
    property int gestureFinishCount: 0
    property int gestureCancelCount: 0
    property string gestureMode: ""
    property real gestureStartX: -1
    property real gestureMoveX: -1

    Window {
        id: window

        width: 620
        height: 180
        visible: true

        EditorTimelineTrackViewport {
            id: viewport

            anchors.fill: parent
            tracks: [
                {
                    id: "visual",
                    name: "Visual",
                    type: "media",
                    enabled: true,
                    locked: false,
                    clips: [
                        {
                            id: "visible-clip",
                            assetId: "image",
                            startMs: 1000,
                            durationMs: 2000,
                            sourceInMs: 0,
                            loop: false,
                            enabled: true
                        },
                        {
                            id: "culled-clip",
                            assetId: "image",
                            startMs: 90000,
                            durationMs: 2000,
                            sourceInMs: 0,
                            loop: false,
                            enabled: true
                        }
                    ]
                },
                {
                    id: "audio",
                    name: "Audio",
                    type: "audio",
                    enabled: true,
                    locked: false,
                    clips: []
                }
            ]
            assets: [
                {
                    id: "image",
                    name: "Image",
                    kind: "static",
                    media: {
                        durationMs: 0
                    }
                }
            ]
            viewport: ({
                    durationMs: 100000,
                    viewportWidth: 500,
                    minimumPixelsPerSecond: 1,
                    maximumPixelsPerSecond: 800,
                    pixelsPerSecond: 40,
                    scrollX: 0
                })
            majorTicks: [
                {
                    x: 0,
                    major: true
                },
                {
                    x: 200,
                    major: true
                }
            ]
            viewportOriginX: 120
            viewportWidth: 500
            selectedTrackId: harness.selectedTrackId
            selectedClipIds: harness.selectedClipId.length > 0 ? [harness.selectedClipId] : []
            gesturePreview: null
            snappingEnabled: true
            trackDragAcceptanceProvider: (track, dragSource) => false
            onFocusRequested: harness.focusRequestCount += 1
            onPlayheadTimeRequested: timeMs => harness.playheadTimeMs = timeMs
            onTrackSelectionRequested: trackId => harness.selectedTrackId = trackId
            onTrackContextRequested: (trackId, source, localX, localY) => harness.contextTrackId = trackId
            onClipSelectionRequested: (trackId, clipId, mode) => {
                harness.selectedClipId = clipId;
                harness.selectedMode = mode;
            }
            onClipContextRequested: (trackId, clipId, source, localX, localY, mode) => harness.contextClipId = clipId
            onClipGestureStarted: (mode, clipId, trackId, viewportX, pixelsPerSecond, snapTolerancePx, sourceDurationMs) => {
                harness.gestureStartCount += 1;
                harness.gestureMode = mode;
                harness.gestureStartX = viewportX;
            }
            onClipGestureMoved: viewportX => {
                harness.gestureMoveCount += 1;
                harness.gestureMoveX = viewportX;
            }
            onClipGestureFinished: harness.gestureFinishCount += 1
            onClipGestureCanceled: harness.gestureCancelCount += 1
        }

        TestCase {
            name: "EditorTimelineTrackViewport"
            when: window.visible

            property var trackList: null
            property var trackHeader: null
            property var visibleClip: null

            function initTestCase() {
                trackList = findChild(viewport, "timelineTrackList");
                trackHeader = findChild(viewport, "timelineTrackHeader-visual");
                visibleClip = findChild(viewport, "timelineClip-visible-clip");
                verify(trackList !== null);
                verify(trackHeader !== null);
                verify(visibleClip !== null);
            }

            function init() {
                harness.focusRequestCount = 0;
                harness.selectedTrackId = "";
                harness.selectedClipId = "";
                harness.selectedMode = "";
                harness.playheadTimeMs = -1;
                harness.contextTrackId = "";
                harness.contextClipId = "";
                harness.gestureStartCount = 0;
                harness.gestureMoveCount = 0;
                harness.gestureFinishCount = 0;
                harness.gestureCancelCount = 0;
                harness.gestureMode = "";
                harness.gestureStartX = -1;
                harness.gestureMoveX = -1;
            }

            function test_virtualizationAndTrackSelection() {
                compare(viewport.trackCount, 2);
                verify(findChild(viewport, "timelineClip-culled-clip") === null);

                mouseClick(trackHeader, trackHeader.width / 2, trackHeader.height / 2, Qt.LeftButton);
                compare(harness.selectedTrackId, "visual");
                compare(harness.focusRequestCount, 1);
            }

            function test_clipSelectionContextAndPlayhead() {
                mouseClick(visibleClip, visibleClip.width / 2, visibleClip.height / 2, Qt.LeftButton);
                compare(harness.selectedClipId, "visible-clip");
                compare(harness.selectedMode, "replace");

                mouseClick(visibleClip, visibleClip.width / 2, visibleClip.height / 2, Qt.RightButton);
                compare(harness.contextClipId, "visible-clip");

                mouseClick(visibleClip, visibleClip.width / 2, visibleClip.height / 2, Qt.LeftButton);
                mouseClick(visibleClip, visibleClip.width / 2, visibleClip.height / 2, Qt.LeftButton);
                verify(harness.playheadTimeMs >= 1000);
                verify(harness.playheadTimeMs <= 3000);
            }

            function test_clipGestureRoutesViewportCoordinates() {
                const startX = visibleClip.width / 2;
                mousePress(visibleClip, startX, visibleClip.height / 2, Qt.LeftButton);
                mouseMove(visibleClip, startX + 20, visibleClip.height / 2, 20);
                mouseRelease(visibleClip, startX + 20, visibleClip.height / 2, Qt.LeftButton);

                compare(harness.gestureStartCount, 1);
                verify(harness.gestureMoveCount >= 1);
                compare(harness.gestureFinishCount, 1);
                compare(harness.gestureCancelCount, 0);
                compare(harness.gestureMode, "move");
                verify(harness.gestureStartX >= 0);
                verify(harness.gestureMoveX > harness.gestureStartX);
            }
        }
    }
}
