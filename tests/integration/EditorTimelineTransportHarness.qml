import QtQuick
import QtTest
import Quickshell
import qs.editor

ShellRoot {
    id: harness

    property int focusRequestCount: 0
    property int playPauseRequestCount: 0
    property int loopRequestCount: 0
    property int undoRequestCount: 0
    property int redoRequestCount: 0
    property int addTrackRequestCount: 0
    property var addTrackSource: null

    Window {
        id: window

        width: 720
        height: 80
        visible: true

        EditorTimelineTransport {
            id: transport

            anchors.fill: parent
            projectDurationMs: 0
            playheadMs: 0
            pixelsPerSecond: 80
            previewPlaying: false
            previewLooping: false
            canUndo: false
            canRedo: false
            onFocusRequested: harness.focusRequestCount += 1
            onPreviewPlayPauseRequested: harness.playPauseRequestCount += 1
            onPreviewLoopRequested: harness.loopRequestCount += 1
            onUndoRequested: harness.undoRequestCount += 1
            onRedoRequested: harness.redoRequestCount += 1
            onAddTrackRequested: (source, localX, localY) => {
                harness.addTrackRequestCount += 1;
                harness.addTrackSource = source;
            }
        }

        TestCase {
            name: "EditorTimelineTransport"
            when: window.visible

            property var playButton: null
            property var loopButton: null
            property var undoButton: null
            property var redoButton: null
            property var addTrackButton: null

            function initTestCase() {
                playButton = findChild(transport, "timelinePlayPauseButton");
                loopButton = findChild(transport, "timelineLoopButton");
                undoButton = findChild(transport, "timelineUndoButton");
                redoButton = findChild(transport, "timelineRedoButton");
                addTrackButton = findChild(transport, "timelineAddTrackButton");
                verify(playButton !== null);
                verify(loopButton !== null);
                verify(undoButton !== null);
                verify(redoButton !== null);
                verify(addTrackButton !== null);
            }

            function test_enablementAndStateReflection() {
                verify(!playButton.enabled);
                verify(!loopButton.enabled);
                verify(!undoButton.enabled);
                verify(!redoButton.enabled);

                transport.projectDurationMs = 60000;
                transport.previewPlaying = true;
                transport.previewLooping = true;
                transport.canUndo = true;
                transport.canRedo = true;

                verify(playButton.enabled);
                compare(playButton.glyph, "pause");
                compare(playButton.accessibleName, "Pause preview");
                verify(playButton.primary);
                verify(loopButton.enabled);
                verify(loopButton.primary);
                verify(undoButton.enabled);
                verify(redoButton.enabled);
            }

            function test_semanticRequests() {
                playButton.activated();
                loopButton.activated();
                undoButton.activated();
                redoButton.activated();
                addTrackButton.activated();

                compare(harness.playPauseRequestCount, 1);
                compare(harness.loopRequestCount, 1);
                compare(harness.undoRequestCount, 1);
                compare(harness.redoRequestCount, 1);
                compare(harness.addTrackRequestCount, 1);
                compare(harness.focusRequestCount, 5);
                compare(harness.addTrackSource, addTrackButton);
            }
        }
    }
}
