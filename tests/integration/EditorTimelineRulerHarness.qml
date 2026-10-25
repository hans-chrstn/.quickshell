import QtQuick
import QtTest
import Quickshell
import qs.editor

ShellRoot {
    id: harness

    property int focusRequestCount: 0
    property int scrubStartCount: 0
    property int scrubFinishCount: 0
    property int scrubCancelCount: 0
    property var scrubTimes: []
    property string selectedMarker: ""
    property bool selectedToggle: false
    property string movedMarker: ""
    property int movedTimeMs: -1
    property string contextMarker: ""
    property int rulerContextCount: 0

    Window {
        id: window

        width: 520
        height: 60
        visible: true

        EditorTimelineRuler {
            id: ruler

            anchors.fill: parent
            rulerData: ({
                    ticks: [
                        {
                            x: 0,
                            major: true,
                            label: "0:00"
                        },
                        {
                            x: 80,
                            major: false,
                            label: ""
                        }
                    ]
                })
            markers: [
                {
                    id: "marker-a",
                    name: "Marker A",
                    timeMs: 1000,
                    triggerType: "manual",
                    enabled: true,
                    actions: []
                }
            ]
            viewport: ({
                    durationMs: 10000,
                    viewportWidth: 400,
                    pixelsPerSecond: 40,
                    minimumPixelsPerSecond: 1,
                    maximumPixelsPerSecond: 800,
                    scrollX: 0
                })
            viewportOriginX: 100
            viewportWidth: 400
            selectedMarkerId: harness.selectedMarker
            triggerLabelProvider: triggerType => "Manual event"
            onFocusRequested: harness.focusRequestCount += 1
            onScrubStarted: harness.scrubStartCount += 1
            onScrubTimeRequested: timeMs => harness.scrubTimes = harness.scrubTimes.concat([timeMs])
            onScrubFinished: harness.scrubFinishCount += 1
            onScrubCanceled: harness.scrubCancelCount += 1
            onMarkerMoveRequested: (markerId, timeMs) => {
                harness.movedMarker = markerId;
                harness.movedTimeMs = timeMs;
            }
            onMarkerSelectionRequested: (markerId, toggle) => {
                harness.selectedMarker = markerId;
                harness.selectedToggle = toggle;
            }
            onMarkerContextRequested: (markerId, source, localX, localY) => harness.contextMarker = markerId
            onRulerContextRequested: (source, localX, localY) => harness.rulerContextCount += 1
        }

        TestCase {
            name: "EditorTimelineRuler"
            when: window.visible

            property var scrubArea: null
            property var contextArea: null
            property var markerSurface: null
            property var markerDrag: null

            function initTestCase() {
                scrubArea = findChild(ruler, "timelineRulerScrubArea");
                contextArea = findChild(ruler, "timelineRulerContextArea");
                markerSurface = findChild(ruler, "timelineMarker-marker-a");
                markerDrag = findChild(ruler, "timelineMarkerDrag-marker-a");
                verify(scrubArea !== null);
                verify(contextArea !== null);
                verify(markerSurface !== null);
                verify(markerDrag !== null);
            }

            function test_markerSelectionAndMovement() {
                mouseClick(markerDrag, markerDrag.width / 2, markerDrag.height / 2, Qt.LeftButton);
                compare(harness.selectedMarker, "marker-a");
                verify(harness.selectedToggle);
                tryCompare(markerSurface, "selected", true);
                compare(harness.focusRequestCount, 1);

                mousePress(markerDrag, markerDrag.width / 2, markerDrag.height / 2, Qt.LeftButton);
                mouseMove(markerDrag, markerDrag.width / 2 + 40, markerDrag.height / 2, 20);
                mouseRelease(markerDrag, markerDrag.width / 2 + 40, markerDrag.height / 2, Qt.LeftButton);
                compare(harness.movedMarker, "marker-a");
                verify(harness.movedTimeMs > 1000);
                verify(!harness.selectedToggle);
            }

            function test_rulerScrubAndContextRequests() {
                mousePress(scrubArea, 120, 15, Qt.LeftButton);
                mouseMove(scrubArea, 160, 15, 20);
                mouseRelease(scrubArea, 160, 15, Qt.LeftButton);
                compare(harness.scrubStartCount, 1);
                compare(harness.scrubFinishCount, 1);
                compare(harness.scrubCancelCount, 0);
                verify(harness.scrubTimes.length >= 2);
                verify(harness.scrubTimes[harness.scrubTimes.length - 1] >= harness.scrubTimes[0]);

                mouseClick(contextArea, 200, 15, Qt.RightButton);
                compare(harness.rulerContextCount, 1);
            }
        }
    }
}
