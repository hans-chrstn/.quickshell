import QtQuick
import qs.components
import qs.core
import "../services/wallpaper/projects/WallpaperTimelineViewport.js" as Viewport

Item {
    id: root

    required property var tracks
    required property var assets
    required property var viewport
    required property var majorTicks
    required property real viewportOriginX
    required property real viewportWidth
    required property string selectedTrackId
    required property var selectedClipIds
    required property var gesturePreview
    required property bool snappingEnabled
    required property var trackDragAcceptanceProvider

    readonly property int trackCount: trackList.count

    signal focusRequested
    signal playheadTimeRequested(int timeMs)
    signal trackSelectionRequested(string trackId)
    signal trackContextRequested(string trackId, Item source, real localX, real localY)
    signal clipSelectionRequested(string trackId, string clipId, string mode)
    signal clipContextRequested(string trackId, string clipId, Item source, real localX, real localY, string mode)
    signal clipGestureStarted(string mode, string clipId, string trackId, real viewportX, real pixelsPerSecond, int snapTolerancePx, int sourceDurationMs)
    signal clipGestureMoved(real viewportX)
    signal clipGestureFinished
    signal clipGestureCanceled
    signal dropPreviewRequested(string trackId, real viewportX, var dragSource)
    signal dropPreviewCleared
    signal dropCommitRequested(string trackId, real viewportX, var dragSource, var dropEvent)

    function assetFor(assetId) {
        return (assets || []).find(asset => asset.id === assetId) || null;
    }

    function displayClip(clip) {
        if (gesturePreview?.clipId !== clip.id || !gesturePreview.timing)
            return clip;
        return Object.assign({}, clip, gesturePreview.timing);
    }

    function selectionMode(modifiers) {
        if (modifiers & Qt.ShiftModifier)
            return "range";
        if (modifiers & Qt.ControlModifier)
            return "toggle";
        return "replace";
    }

    ListView {
        id: trackList

        objectName: "timelineTrackList"
        anchors.fill: parent
        clip: true
        reuseItems: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.tracks || []
        spacing: 3

        delegate: Rectangle {
            id: trackLane

            required property var modelData
            readonly property var trackData: modelData

            objectName: "timelineTrackLane-" + String(trackData.id || "")
            width: ListView.view.width
            height: 42
            color: Theme.fillFaint

            HighlightableSurface {
                id: trackHeader

                objectName: "timelineTrackHeader-" + String(trackLane.trackData.id || "")
                width: root.viewportOriginX
                height: parent.height
                interactive: false
                selected: root.selectedTrackId === trackLane.trackData.id && root.selectedClipIds.length === 0
                baseColor: Theme.fillFaint
                cornerRadius: 0

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 20
                    spacing: 1

                    Text {
                        width: parent.width
                        text: trackLane.trackData.name
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        font.family: Design.fontText
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }

                    Text {
                        width: parent.width
                        text: trackLane.trackData.type
                        color: Theme.textSecondary
                        elide: Text.ElideRight
                        font.family: Design.fontText
                        font.pixelSize: 8
                    }
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: {
                        root.focusRequested();
                        root.trackSelectionRequested(String(trackLane.trackData.id || ""));
                    }
                }

                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: eventPoint => {
                        root.focusRequested();
                        root.trackContextRequested(String(trackLane.trackData.id || ""), trackHeader, eventPoint.position.x, eventPoint.position.y);
                    }
                }
            }

            Item {
                id: laneViewport

                objectName: "timelineLaneViewport-" + String(trackLane.trackData.id || "")
                x: root.viewportOriginX
                width: root.viewportWidth
                height: parent.height
                clip: true

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    propagateComposedEvents: true
                    onDoubleClicked: mouse => {
                        root.focusRequested();
                        root.playheadTimeRequested(Viewport.viewportXToTime(root.viewport, mouse.x));
                    }
                }

                Repeater {
                    model: root.majorTicks

                    delegate: Rectangle {
                        required property var modelData

                        x: modelData.x
                        width: 1
                        height: parent.height
                        color: Theme.separator
                        opacity: 0.26
                    }
                }

                Repeater {
                    model: Viewport.visibleClips(trackLane.trackData.clips, root.viewport, 80)

                    delegate: EditorTimelineClip {
                        id: clipItem

                        required property var modelData
                        readonly property var timelineClip: modelData
                        readonly property var visibleClip: root.displayClip(timelineClip)
                        readonly property var timelineAsset: root.assetFor(timelineClip.assetId)

                        objectName: "timelineClip-" + String(timelineClip.id || "")
                        x: Viewport.timeToViewportX(root.viewport, visibleClip.startMs)
                        y: 4
                        width: Math.max(12, visibleClip.durationMs * root.viewport.pixelsPerSecond / 1000)
                        height: parent.height - 8
                        clipData: timelineClip
                        assetData: timelineAsset
                        selected: root.selectedClipIds.indexOf(timelineClip.id) >= 0
                        onActivated: modifiers => {
                            root.focusRequested();
                            root.clipSelectionRequested(String(trackLane.trackData.id || ""), String(timelineClip.id || ""), root.selectionMode(modifiers));
                        }
                        onDoubleActivated: (localX, modifiers) => {
                            root.focusRequested();
                            root.playheadTimeRequested(Viewport.viewportXToTime(root.viewport, clipItem.x + localX));
                        }
                        onContextRequested: (localX, localY, modifiers) => {
                            root.focusRequested();
                            root.clipContextRequested(String(trackLane.trackData.id || ""), String(timelineClip.id || ""), clipItem, localX, localY, root.selectionMode(modifiers));
                        }
                        onGestureStarted: (mode, localX) => {
                            root.focusRequested();
                            const viewportX = clipItem.mapToItem(root, localX, 0).x - root.viewportOriginX;
                            root.clipGestureStarted(mode, String(timelineClip.id || ""), String(trackLane.trackData.id || ""), viewportX, root.viewport.pixelsPerSecond, 8, timelineAsset?.media?.durationMs || 0);
                        }
                        onGestureMoved: localX => {
                            const viewportX = clipItem.mapToItem(root, localX, 0).x - root.viewportOriginX;
                            root.clipGestureMoved(viewportX);
                        }
                        onGestureFinished: root.clipGestureFinished()
                        onGestureCanceled: root.clipGestureCanceled()
                    }
                }

                DropArea {
                    anchors.fill: parent
                    keys: ["wallpaper-editor-media"]
                    onEntered: drag => {
                        drag.accepted = root.trackDragAcceptanceProvider(trackLane.trackData, drag.source);
                        if (drag.accepted)
                            root.dropPreviewRequested(String(trackLane.trackData.id || ""), drag.x, drag.source);
                    }
                    onPositionChanged: drag => {
                        if (root.trackDragAcceptanceProvider(trackLane.trackData, drag.source))
                            root.dropPreviewRequested(String(trackLane.trackData.id || ""), drag.x, drag.source);
                    }
                    onExited: root.dropPreviewCleared()
                    onDropped: drop => root.dropCommitRequested(String(trackLane.trackData.id || ""), drop.x, drop.source, drop)
                }
            }
        }
    }

    DropArea {
        anchors.fill: parent
        enabled: trackList.count === 0
        keys: ["wallpaper-editor-media"]
        onEntered: drag => {
            drag.accepted = drag.source?.dragAvailable === true;
            if (drag.accepted)
                root.dropPreviewRequested("", drag.x - root.viewportOriginX, drag.source);
        }
        onPositionChanged: drag => root.dropPreviewRequested("", drag.x - root.viewportOriginX, drag.source)
        onExited: root.dropPreviewCleared()
        onDropped: drop => root.dropCommitRequested("", drop.x - root.viewportOriginX, drop.source, drop)
    }

    Column {
        anchors.centerIn: parent
        visible: trackList.count === 0
        spacing: 4

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No tracks yet"
            color: Theme.textPrimary
            font.family: Design.fontText
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "The timeline is ready for your first media track."
            color: Theme.textSecondary
            font.family: Design.fontText
            font.pixelSize: 9
        }
    }
}
