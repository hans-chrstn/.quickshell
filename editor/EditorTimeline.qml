import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.components.menus
import qs.core
import qs.services.wallpaper.projects
import "../services/wallpaper/projects/WallpaperTimelineModel.js" as TimelineModel
import "../services/wallpaper/projects/WallpaperTimelineRuler.js" as Ruler
import "../services/wallpaper/projects/WallpaperTimelineViewport.js" as Viewport

Rectangle {
    id: root

    readonly property var project: WallpaperEditorService.activeProject?.project || null
    readonly property var markers: project?.markers || []
    readonly property int projectDurationMs: project?.durationMs || 0
    readonly property int displayDurationMs: Math.max(10000, projectDurationMs)
    readonly property real labelRailWidth: Math.min(116, Math.max(86, width * 0.11))
    readonly property real viewportOriginX: 10 + labelRailWidth
    readonly property real viewportWidth: Math.max(1, width - viewportOriginX - 10)
    readonly property real minimumTimelinePixelsPerSecond: Math.max(1, Math.min(20, viewportWidth * 1000 / Math.max(1000, displayDurationMs)))
    property real pixelsPerSecond: 80
    property real scrollX: 0
    property int playheadMs: 0
    property bool previewPlaying: false
    property bool previewLooping: false
    property int loopStartMs: 0
    property int loopEndMs: 0
    property bool scrubbing: false
    property bool snappingEnabled: true
    property bool dropPreviewVisible: false
    property string dropPreviewTrackId: ""
    property int dropPreviewTimeMs: 0
    property int dropPreviewDurationMs: 5000
    property string contextMarkerId: ""
    property var contextMarkerSource: null
    signal previewPlayPauseRequested
    signal previewLoopRequested
    signal undoRequested
    signal redoRequested
    signal loopRegionChanged(int startMs, int endMs)
    signal scrubStarted
    signal scrubFinished
    readonly property var viewport: Viewport.normalize({
        durationMs: displayDurationMs,
        viewportWidth: viewportWidth,
        pixelsPerSecond: pixelsPerSecond,
        minimumPixelsPerSecond: minimumTimelinePixelsPerSecond,
        maximumPixelsPerSecond: 800,
        scrollX: scrollX
    })
    readonly property var rulerData: Ruler.ticks(viewport, 40, 10, 62, 256)

    function contextMarker() {
        return markers.find(marker => marker.id === contextMarkerId) || null;
    }

    function triggerLabel(triggerType) {
        switch (String(triggerType || "manual")) {
        case "time":
            return "Time";
        case "date":
            return "Date";
        case "weather":
            return "Weather";
        case "battery":
            return "Battery / power";
        case "workspace":
            return "Workspace";
        case "application":
            return "Application";
        case "window":
            return "Window state";
        case "media":
            return "Media state";
        case "lock":
            return "Session lock";
        case "monitor":
            return "Monitor state";
        default:
            return "Manual event";
        }
    }

    function trackAcceptsDrag(track, dragSource) {
        return dragSource?.asset && track?.enabled !== false && track?.locked !== true && TimelineModel.trackAcceptsAsset(track.type, dragSource.asset.declaredKind);
    }

    function updateDropPreview(trackId, localX, dragSource) {
        dropPreviewTrackId = String(trackId || "");
        dropPreviewTimeMs = Viewport.viewportXToTime(viewport, Math.max(0, localX));
        dropPreviewDurationMs = Math.max(1, Number(dragSource?.sourceDurationMs) || 5000);
        dropPreviewVisible = true;
    }

    function clearDropPreview() {
        dropPreviewVisible = false;
        dropPreviewTrackId = "";
    }

    function commitDrop(trackId, localX, dragSource) {
        const accepted = WallpaperTimelineService.dropAsset(dragSource?.asset?.id || "", trackId, Viewport.viewportXToTime(viewport, Math.max(0, localX)), dragSource?.sourceDurationMs || 0);
        clearDropPreview();
        return accepted;
    }

    function scrollBy(deltaX) {
        const next = Viewport.scrollBy(viewport, deltaX);
        scrollX = next.scrollX;
    }

    function zoomAt(requestedScale, localX) {
        const next = Viewport.zoomAround(viewport, requestedScale, Math.max(0, Math.min(viewportWidth, localX - viewportOriginX)));
        pixelsPerSecond = next.pixelsPerSecond;
        scrollX = next.scrollX;
    }

    function scrollFromOverview(localX) {
        const state = Viewport.normalize(viewport);
        const thumbWidth = Math.max(24, viewportWidth * viewportWidth / Math.max(viewportWidth, state.contentWidth));
        const center = Math.max(0, Math.min(viewportWidth, Number(localX) - thumbWidth / 2));
        const travel = Math.max(1, viewportWidth - thumbWidth);
        scrollX = state.maximumScrollX * center / travel;
    }

    function removeSelection() {
        const kind = WallpaperEditorSelectionService.kind;
        if (kind === "clips")
            return WallpaperTimelineService.removeSelectedClips();
        if (kind === "marker")
            return WallpaperTimelineService.removeMarker(WallpaperEditorSelectionService.selectedMarkerId);
        if (kind === "track")
            return trackRemovalMenu.requestRemoval(WallpaperEditorSelectionService.timelineSelection.trackId);
        return false;
    }

    radius: Design.editorSectionRadius
    color: Theme.fillFaint
    border.width: 1
    border.color: Theme.separatorQuiet
    clip: true
    focus: true

    Component.onCompleted: forceActiveFocus()
    onVisibleChanged: if (visible)
        forceActiveFocus()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        EditorTimelineTransport {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            projectDurationMs: root.projectDurationMs
            playheadMs: root.playheadMs
            pixelsPerSecond: root.pixelsPerSecond
            previewPlaying: root.previewPlaying
            previewLooping: root.previewLooping
            canUndo: WallpaperTimelineService.canUndo
            canRedo: WallpaperTimelineService.canRedo
            onFocusRequested: root.forceActiveFocus()
            onPreviewPlayPauseRequested: root.previewPlayPauseRequested()
            onPreviewLoopRequested: root.previewLoopRequested()
            onUndoRequested: root.undoRequested()
            onRedoRequested: root.redoRequested()
            onAddTrackRequested: (source, localX, localY) => trackMenu.openFor(source, localX, localY)
        }

        EditorTimelineRuler {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            rulerData: root.rulerData
            markers: root.markers
            viewport: root.viewport
            viewportOriginX: root.viewportOriginX
            viewportWidth: root.viewportWidth
            selectedMarkerId: WallpaperEditorSelectionService.selectedMarkerId
            triggerLabelProvider: root.triggerLabel
            onFocusRequested: root.forceActiveFocus()
            onScrubStarted: {
                root.scrubbing = true;
                root.scrubStarted();
            }
            onScrubTimeRequested: timeMs => root.playheadMs = timeMs
            onScrubFinished: {
                root.scrubFinished();
                root.scrubbing = false;
            }
            onScrubCanceled: root.scrubbing = false
            onMarkerMoveRequested: (markerId, timeMs) => WallpaperTimelineService.moveMarker(markerId, timeMs)
            onMarkerSelectionRequested: (markerId, toggle) => WallpaperEditorSelectionService.selectMarker(markerId, toggle)
            onMarkerContextRequested: (markerId, source, localX, localY) => {
                root.contextMarkerId = markerId;
                root.contextMarkerSource = source;
                markerActionMenu.openFor(source, localX, localY);
            }
            onRulerContextRequested: (source, localX, localY) => markerMenu.openFor(source, localX, localY)
        }

        EditorTimelineTrackViewport {
            Layout.fillWidth: true
            Layout.fillHeight: true
            tracks: root.project?.tracks || []
            assets: root.project?.assets || []
            viewport: root.viewport
            majorTicks: root.rulerData.ticks.filter(tick => tick.major)
            viewportOriginX: root.viewportOriginX
            viewportWidth: root.viewportWidth
            selectedTrackId: WallpaperTimelineService.selection.trackId
            selectedClipIds: WallpaperTimelineService.selection.clipIds
            gesturePreview: WallpaperTimelineService.session?.preview || null
            snappingEnabled: root.snappingEnabled
            trackDragAcceptanceProvider: (track, dragSource) => root.trackAcceptsDrag(track, dragSource)
            onFocusRequested: root.forceActiveFocus()
            onPlayheadTimeRequested: timeMs => root.playheadMs = timeMs
            onTrackSelectionRequested: trackId => WallpaperTimelineService.selectTrack(trackId)
            onTrackContextRequested: (trackId, source, localX, localY) => trackRemovalMenu.openFor(trackId, source, localX, localY)
            onClipSelectionRequested: (trackId, clipId, mode) => WallpaperTimelineService.selectClip(trackId, clipId, mode)
            onClipContextRequested: (trackId, clipId, source, localX, localY, mode) => {
                if (WallpaperTimelineService.selection.clipIds.indexOf(clipId) < 0)
                    WallpaperTimelineService.selectClip(trackId, clipId, mode);
                clipMenu.openFor(source, localX, localY);
            }
            onClipGestureStarted: (mode, clipId, trackId, viewportX, pixelsPerSecond, snapTolerancePx, sourceDurationMs) => {
                root.scrubbing = true;
                root.scrubStarted();
                WallpaperTimelineService.beginGesture(mode, clipId, trackId, viewportX, pixelsPerSecond, snapTolerancePx, sourceDurationMs);
            }
            onClipGestureMoved: viewportX => WallpaperTimelineService.updateGesture(viewportX, root.snappingEnabled)
            onClipGestureFinished: {
                if (WallpaperTimelineService.gestureActive)
                    WallpaperTimelineService.finishGesture();
                root.scrubbing = false;
            }
            onClipGestureCanceled: {
                if (WallpaperTimelineService.gestureActive)
                    WallpaperTimelineService.cancelGesture();
                root.scrubbing = false;
            }
            onDropPreviewRequested: (trackId, viewportX, dragSource) => root.updateDropPreview(trackId, viewportX, dragSource)
            onDropPreviewCleared: root.clearDropPreview()
            onDropCommitRequested: (trackId, viewportX, dragSource, dropEvent) => {
                if ((trackId.length === 0 || root.trackAcceptsDrag((root.project?.tracks || []).find(track => track.id === trackId), dragSource)) && root.commitDrop(trackId, viewportX, dragSource))
                    dropEvent.acceptProposedAction();
            }
        }
    }

    EditorTimelinePlayheadLayer {
        anchors.fill: parent
        viewport: root.viewport
        viewportOriginX: root.viewportOriginX
        viewportWidth: root.viewportWidth
        playheadMs: root.playheadMs
        loopEnabled: root.previewLooping
        loopStartMs: root.loopStartMs
        loopEndMs: root.loopEndMs
        onFocusRequested: root.forceActiveFocus()
        onScrubStarted: {
            root.scrubbing = true;
            root.scrubStarted();
        }
        onScrubTimeRequested: timeMs => root.playheadMs = timeMs
        onScrubFinished: {
            root.scrubFinished();
            root.scrubbing = false;
        }
        onScrubCanceled: root.scrubbing = false
        onLoopRegionRequested: (startMs, endMs) => root.loopRegionChanged(startMs, endMs)
    }

    Rectangle {
        visible: root.dropPreviewVisible
        x: root.viewportOriginX + Viewport.timeToViewportX(root.viewport, root.dropPreviewTimeMs)
        y: 72 + (root.dropPreviewTrackId.length > 0 ? Math.max(0, (root.project?.tracks || []).findIndex(track => track.id === root.dropPreviewTrackId)) * 45 + 4 : 12)
        width: Math.max(14, Math.min(root.viewportWidth, root.dropPreviewDurationMs * root.viewport.pixelsPerSecond / 1000))
        height: 34
        radius: 8
        color: Theme.tintActive(Theme.accent)
        border.width: 1
        border.color: Theme.accent
        opacity: 0.78
        z: 6

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 3
            radius: 1.5
            color: Theme.accent
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            if (wheel.modifiers & Qt.ControlModifier) {
                const factor = wheel.angleDelta.y > 0 ? 1.16 : 1 / 1.16;
                root.zoomAt(root.pixelsPerSecond * factor, wheel.x);
            } else {
                const amount = wheel.angleDelta.x !== 0 ? wheel.angleDelta.x : wheel.angleDelta.y;
                root.scrollBy(-amount * 0.8);
            }
            wheel.accepted = true;
        }
    }

    Item {
        id: timelineOverview
        visible: root.viewport.maximumScrollX > 0
        x: root.viewportOriginX
        y: root.height - 9
        width: root.viewportWidth
        height: 4
        z: 9

        Rectangle {
            anchors.fill: parent
            radius: 2
            color: Theme.fillQuiet
        }

        Rectangle {
            id: overviewThumb
            x: root.viewport.maximumScrollX > 0 ? root.scrollX / root.viewport.maximumScrollX * Math.max(0, parent.width - overviewThumb.width) : 0
            width: Math.max(28, parent.width * parent.width / Math.max(parent.width, root.viewport.contentWidth))
            height: parent.height
            radius: 2
            color: Theme.tintLine(Theme.accent)
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onPressed: mouse => root.scrollFromOverview(mouse.x)
            onPositionChanged: mouse => {
                if (pressed)
                    root.scrollFromOverview(mouse.x);
            }
        }
    }

    ContextMenu {
        id: markerMenu

        actions: [
            {
                id: "add-marker",
                label: "Add marker at playhead",
                enabled: root.projectDurationMs > 0
            }
        ]

        onActionTriggered: actionId => {
            if (actionId === "add-marker")
                WallpaperTimelineService.addMarker(root.playheadMs, "manual");
        }
    }

    ContextMenu {
        id: markerActionMenu

        actions: [
            {
                id: "toggle-marker",
                label: root.contextMarker()?.enabled === false ? "Enable marker" : "Disable marker",
                enabled: root.contextMarkerId.length > 0
            },
            {
                id: "set-trigger",
                label: "Set trigger (" + root.triggerLabel(root.contextMarker()?.triggerType) + ")",
                enabled: root.contextMarkerId.length > 0
            },
            {
                id: "action-summary",
                label: "Actions configured: " + (root.contextMarker()?.actions?.length || 0),
                enabled: false
            },
            {
                id: "remove-marker",
                label: "Remove marker",
                destructive: true,
                enabled: root.contextMarkerId.length > 0
            }
        ]

        onActionTriggered: actionId => {
            const marker = root.contextMarker();
            if (!marker)
                return;
            if (actionId === "toggle-marker")
                WallpaperTimelineService.updateMarker(marker.id, {
                    enabled: marker.enabled === false
                });
            else if (actionId === "set-trigger") {
                triggerTypeMenu.openFor(root.contextMarkerSource, 0, root.contextMarkerSource.height);
                return;
            } else if (actionId === "remove-marker")
                WallpaperTimelineService.removeMarker(marker.id);
            root.contextMarkerId = "";
        }
    }

    ContextMenu {
        id: triggerTypeMenu

        actions: [
            {
                id: "manual",
                label: "Manual event"
            },
            {
                id: "time",
                label: "Time"
            },
            {
                id: "date",
                label: "Date"
            },
            {
                id: "weather",
                label: "Weather"
            },
            {
                id: "battery",
                label: "Battery / power"
            },
            {
                id: "workspace",
                label: "Workspace"
            },
            {
                id: "application",
                label: "Application"
            },
            {
                id: "window",
                label: "Window state"
            },
            {
                id: "media",
                label: "Media state"
            },
            {
                id: "lock",
                label: "Session lock"
            },
            {
                id: "monitor",
                label: "Monitor state"
            }
        ]

        onActionTriggered: actionId => {
            const marker = root.contextMarker();
            if (marker)
                WallpaperTimelineService.updateMarker(marker.id, {
                    triggerType: actionId
                });
            root.contextMarkerId = "";
            root.contextMarkerSource = null;
        }
        onClosed: {
            if (!markerActionMenu.visible)
                root.contextMarkerSource = null;
        }
    }

    ContextMenu {
        id: clipMenu

        actions: [
            {
                id: "remove-clips",
                label: WallpaperTimelineService.selection.clipIds.length > 1 ? "Remove selected clips" : "Remove clip",
                destructive: true,
                enabled: WallpaperTimelineService.selection.clipIds.length > 0
            }
        ]
        onActionTriggered: actionId => {
            if (actionId === "remove-clips")
                WallpaperTimelineService.removeSelectedClips();
        }
    }

    ContextMenu {
        id: trackMenu

        actions: [
            {
                id: "add-media-track",
                label: "Add Media track",
                enabled: true
            },
            {
                id: "add-audio-track",
                label: "Add Audio track",
                enabled: true
            }
        ]
        onActionTriggered: actionId => {
            if (actionId === "add-media-track")
                WallpaperTimelineService.addTrack("media");
            else if (actionId === "add-audio-track")
                WallpaperTimelineService.addTrack("audio");
        }
    }

    EditorTrackMenu {
        id: trackRemovalMenu
        onDismissed: root.forceActiveFocus()
    }
}
