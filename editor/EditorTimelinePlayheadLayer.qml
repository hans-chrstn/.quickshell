import QtQuick
import qs.core
import "../services/wallpaper/projects/WallpaperTimelineRuler.js" as Ruler
import "../services/wallpaper/projects/WallpaperTimelineViewport.js" as Viewport

Item {
    id: root

    required property var viewport
    required property real viewportOriginX
    required property real viewportWidth
    required property int playheadMs
    required property bool loopEnabled
    required property int loopStartMs
    required property int loopEndMs

    readonly property var playhead: Ruler.playhead(viewport, playheadMs)
    readonly property real loopStartX: Viewport.timeToViewportX(viewport, loopStartMs)
    readonly property real loopEndX: Viewport.timeToViewportX(viewport, loopEndMs)
    readonly property real visibleLoopStartX: Math.max(0, Math.min(viewportWidth, loopStartX))
    readonly property real visibleLoopEndX: Math.max(0, Math.min(viewportWidth, loopEndX))

    signal focusRequested
    signal scrubStarted
    signal scrubTimeRequested(int timeMs)
    signal scrubFinished
    signal scrubCanceled
    signal loopRegionRequested(int startMs, int endMs)

    function timeAt(source, localX) {
        const viewportX = source.mapToItem(root, localX, 0).x - viewportOriginX;
        return Viewport.viewportXToTime(viewport, viewportX);
    }

    Rectangle {
        id: playheadLine

        objectName: "timelinePlayhead"
        visible: root.playhead.visible
        x: root.viewportOriginX + root.playhead.x
        y: 38
        width: 1
        height: root.height - 38
        color: Design.blue
        z: 5

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 7
            height: 7
            radius: 3.5
            color: Design.blue
        }

        MouseArea {
            id: playheadDragArea

            property bool dragging: false

            objectName: "timelinePlayheadDragArea"
            x: -6
            width: 13
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            cursorShape: Qt.SizeHorCursor
            onPressed: mouse => {
                dragging = true;
                root.focusRequested();
                root.scrubStarted();
                root.scrubTimeRequested(root.timeAt(playheadDragArea, mouse.x));
            }
            onPositionChanged: mouse => {
                if (dragging)
                    root.scrubTimeRequested(root.timeAt(playheadDragArea, mouse.x));
            }
            onReleased: {
                if (dragging)
                    root.scrubFinished();
                dragging = false;
            }
            onCanceled: {
                dragging = false;
                root.scrubCanceled();
            }
        }
    }

    Rectangle {
        objectName: "timelineLoopRail"
        visible: root.loopEnabled && root.loopEndMs > root.loopStartMs && root.loopEndX > 0 && root.loopStartX < root.viewportWidth
        x: root.viewportOriginX + root.visibleLoopStartX
        y: 42
        width: Math.max(1, root.visibleLoopEndX - root.visibleLoopStartX)
        height: 3
        radius: 1.5
        color: Qt.rgba(Design.blue.r, Design.blue.g, Design.blue.b, 0.48)
        z: 2
    }

    Repeater {
        model: root.loopEnabled ? ["start", "end"] : []

        delegate: Rectangle {
            id: loopHandle

            required property string modelData
            readonly property bool startHandle: modelData === "start"
            readonly property real handleX: startHandle ? root.loopStartX : root.loopEndX

            objectName: "timelineLoopHandle-" + modelData
            x: root.viewportOriginX + handleX - width / 2
            y: 36
            width: 5
            height: 15
            visible: root.loopEnabled && handleX >= 0 && handleX <= root.viewportWidth
            color: Qt.rgba(Design.blue.r, Design.blue.g, Design.blue.b, 0.86)
            radius: 4
            z: 8

            MouseArea {
                id: loopHandleDrag

                property bool dragging: false

                objectName: "timelineLoopHandleDrag-" + loopHandle.modelData
                anchors.fill: parent
                anchors.margins: -5
                acceptedButtons: Qt.LeftButton
                preventStealing: true
                cursorShape: Qt.SizeHorCursor
                onPressed: {
                    dragging = true;
                    root.focusRequested();
                    root.scrubStarted();
                }
                onPositionChanged: mouse => {
                    if (!dragging)
                        return;
                    const time = root.timeAt(loopHandleDrag, mouse.x);
                    if (loopHandle.startHandle)
                        root.loopRegionRequested(Math.min(time, root.loopEndMs - 1), root.loopEndMs);
                    else
                        root.loopRegionRequested(root.loopStartMs, Math.max(time, root.loopStartMs + 1));
                }
                onReleased: {
                    if (dragging)
                        root.scrubFinished();
                    dragging = false;
                }
                onCanceled: {
                    dragging = false;
                    root.scrubCanceled();
                }
            }
        }
    }
}
