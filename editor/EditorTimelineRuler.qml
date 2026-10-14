import QtQuick
import qs.components
import qs.core
import "../services/wallpaper/projects/WallpaperTimelineRuler.js" as Ruler
import "../services/wallpaper/projects/WallpaperTimelineViewport.js" as Viewport

Rectangle {
    id: root

    required property var rulerData
    required property var markers
    required property var viewport
    required property real viewportOriginX
    required property real viewportWidth
    required property string selectedMarkerId
    required property var triggerLabelProvider
    property bool scrubbing: false

    signal focusRequested
    signal scrubStarted
    signal scrubTimeRequested(int timeMs)
    signal scrubFinished
    signal scrubCanceled
    signal markerMoveRequested(string markerId, int timeMs)
    signal markerSelectionRequested(string markerId, bool toggle)
    signal markerContextRequested(string markerId, Item source, real localX, real localY)
    signal rulerContextRequested(Item source, real localX, real localY)

    implicitHeight: 30
    color: Qt.rgba(1, 1, 1, 0.018)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.035)

    Text {
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        text: "TRACKS"
        color: Design.textMuted
        opacity: 0.68
        font.family: Design.fontText
        font.pixelSize: 8
        font.letterSpacing: 0.8
        font.weight: Font.DemiBold
    }

    Item {
        id: viewportLayer

        x: root.viewportOriginX
        width: root.viewportWidth
        height: parent.height
        clip: true

        Repeater {
            model: root.rulerData.ticks

            delegate: Item {
                required property var modelData
                x: modelData.x
                width: 1
                height: parent.height

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: 1
                    height: modelData.major ? 11 : 6
                    color: modelData.major ? Design.textMuted : Design.separator
                    opacity: modelData.major ? 0.72 : 0.5
                }

                Text {
                    visible: modelData.major
                    x: 4
                    y: 3
                    text: modelData.label
                    color: Design.textMuted
                    font.family: Design.fontMono
                    font.pixelSize: 8
                }
            }
        }

        Repeater {
            model: root.markers

            delegate: HighlightableSurface {
                id: markerItem

                required property var modelData
                property bool dragging: false
                property real dragTimeMs: Number(modelData.timeMs) || 0
                readonly property real displayTimeMs: dragging ? dragTimeMs : Number(modelData.timeMs) || 0
                readonly property real markerX: Viewport.timeToViewportX(root.viewport, displayTimeMs)

                objectName: "timelineMarker-" + String(modelData.id || "")
                x: markerX - 1
                y: 0
                width: 2
                height: parent.height
                visible: markerX >= 0 && markerX <= root.viewportWidth
                accentColor: Design.yellow
                baseColor: "transparent"
                focused: markerHover.hovered
                selected: root.selectedMarkerId === modelData.id
                labelText: modelData.name
                labelVisible: highlighted
                cornerRadius: 1
                opacity: modelData.enabled ? 0.9 : 0.45
                z: 6

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 1
                    width: 8
                    height: 8
                    radius: 4
                    color: markerItem.highlighted ? Design.text : markerItem.accentColor
                    scale: markerItem.highlighted ? 1.2 : 1

                    Behavior on color {
                        ColorAnimation {
                            duration: 110
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: 90
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                IslandToolTip {
                    visible: markerHover.hovered && !markerDrag.pressed
                    text: modelData.name + " · " + root.triggerLabelProvider(modelData.triggerType) + (modelData.actions?.length > 0 ? " · " + modelData.actions.length + " action" + (modelData.actions.length === 1 ? "" : "s") : "") + " · " + Ruler.label(markerItem.displayTimeMs, 1000)
                }

                HoverHandler {
                    id: markerHover
                }

                onSurfaceContextRequested: (localX, localY) => root.markerContextRequested(String(modelData.id || ""), markerItem, localX, localY)

                MouseArea {
                    id: markerDrag

                    property real pressX: 0
                    property bool dragMoved: false

                    objectName: "timelineMarkerDrag-" + String(modelData.id || "")
                    anchors.fill: parent
                    anchors.margins: -6
                    acceptedButtons: Qt.LeftButton
                    preventStealing: true
                    cursorShape: Qt.SizeHorCursor
                    onPressed: mouse => {
                        pressX = mouse.x;
                        dragMoved = false;
                        markerItem.dragging = true;
                        markerItem.dragTimeMs = modelData.timeMs;
                        root.focusRequested();
                    }
                    onPositionChanged: mouse => {
                        if (!pressed)
                            return;
                        if (Math.abs(mouse.x - pressX) > 2)
                            dragMoved = true;
                        const localX = markerDrag.mapToItem(viewportLayer, mouse.x, 0).x;
                        markerItem.dragTimeMs = Viewport.viewportXToTime(root.viewport, localX);
                    }
                    onReleased: {
                        const markerId = String(modelData?.id || "");
                        if (markerItem.dragging && markerId.length > 0 && dragMoved)
                            root.markerMoveRequested(markerId, markerItem.dragTimeMs);
                        markerItem.dragging = false;
                        if (markerId.length > 0)
                            root.markerSelectionRequested(markerId, !dragMoved);
                        dragMoved = false;
                    }
                    onCanceled: markerItem.dragging = false
                }
            }
        }

        MouseArea {
            id: scrubArea

            objectName: "timelineRulerScrubArea"
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            onPressed: mouse => {
                root.scrubbing = true;
                root.scrubStarted();
                root.scrubTimeRequested(Viewport.viewportXToTime(root.viewport, mouse.x));
            }
            onPositionChanged: mouse => {
                if (root.scrubbing)
                    root.scrubTimeRequested(Viewport.viewportXToTime(root.viewport, mouse.x));
            }
            onReleased: {
                if (root.scrubbing)
                    root.scrubFinished();
                root.scrubbing = false;
            }
            onCanceled: {
                root.scrubbing = false;
                root.scrubCanceled();
            }
        }

        MouseArea {
            id: contextArea

            objectName: "timelineRulerContextArea"
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            z: 4
            onPressed: mouse => {
                root.focusRequested();
                root.rulerContextRequested(contextArea, mouse.x, mouse.y);
            }
        }
    }
}
