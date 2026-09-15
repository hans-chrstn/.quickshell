import QtQuick
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
    readonly property var playhead: Ruler.playhead(viewport, playheadMs)
    readonly property real loopStartX: Viewport.timeToViewportX(viewport, loopStartMs)
    readonly property real loopEndX: Viewport.timeToViewportX(viewport, loopEndMs)
    readonly property real visibleLoopStartX: Math.max(0, Math.min(viewportWidth, loopStartX))
    readonly property real visibleLoopEndX: Math.max(0, Math.min(viewportWidth, loopEndX))

    function assetFor(assetId) {
        return (project?.assets || []).find(asset => asset.id === assetId) || null;
    }

    function displayClip(clip) {
        const preview = WallpaperTimelineService.session?.preview;
        if (preview?.clipId !== clip.id || !preview.timing)
            return clip;
        return Object.assign({}, clip, preview.timing);
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

    function selectionMode(modifiers) {
        if (modifiers & Qt.ShiftModifier)
            return "range";
        if (modifiers & Qt.ControlModifier)
            return "toggle";
        return "replace";
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

    radius: Design.editorSectionRadius
    color: Qt.rgba(1, 1, 1, 0.025)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.045)
    clip: true
    focus: true

    Component.onCompleted: forceActiveFocus()
    onVisibleChanged: if (visible)
        forceActiveFocus()

    Keys.onPressed: event => {
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_A) {
            WallpaperTimelineService.selectAllClips();
            event.accepted = true;
        } else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
            if (WallpaperTimelineService.selection.clipIds.length > 0) {
                WallpaperTimelineService.removeSelectedClips();
                event.accepted = true;
            }
        } else if (event.key === Qt.Key_Home) {
            root.playheadMs = 0;
            root.scrollX = 0;
            event.accepted = true;
        } else if (event.key === Qt.Key_End) {
            root.playheadMs = root.projectDurationMs;
            root.scrollX = root.viewport.maximumScrollX;
            event.accepted = true;
        } else if (event.key === Qt.Key_PageUp) {
            root.scrollBy(-root.viewportWidth * 0.8);
            event.accepted = true;
        } else if (event.key === Qt.Key_PageDown) {
            root.scrollBy(root.viewportWidth * 0.8);
            event.accepted = true;
        } else if (event.key === Qt.Key_Space) {
            root.previewPlayPauseRequested();
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Z) {
            if (event.modifiers & Qt.ShiftModifier)
                root.redoRequested();
            else
                root.undoRequested();
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Y) {
            root.redoRequested();
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Timeline"
                color: Design.text
                font.family: Design.fontText
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            GlyphButton {
                id: previewTransportButton
                implicitWidth: 25
                implicitHeight: 25
                glyph: root.previewPlaying ? "pause" : "play"
                accessibleName: root.previewPlaying ? "Pause preview" : "Play preview"
                toolTip: accessibleName
                enabled: root.projectDurationMs > 0
                primary: root.previewPlaying
                onActivated: {
                    root.forceActiveFocus();
                    root.previewPlayPauseRequested();
                }
            }

            GlyphButton {
                implicitWidth: 25
                implicitHeight: 25
                glyph: "repeat"
                accessibleName: root.previewLooping ? "Disable preview loop" : "Enable preview loop"
                toolTip: accessibleName
                primary: root.previewLooping
                enabled: root.projectDurationMs > 0
                onActivated: {
                    root.forceActiveFocus();
                    root.previewLoopRequested();
                }
            }

            GlyphButton {
                implicitWidth: 25
                implicitHeight: 25
                glyph: "undo"
                accessibleName: "Undo timeline edit"
                toolTip: accessibleName
                enabled: WallpaperTimelineService.canUndo
                onActivated: {
                    root.forceActiveFocus();
                    root.undoRequested();
                }
            }

            GlyphButton {
                implicitWidth: 25
                implicitHeight: 25
                glyph: "redo"
                accessibleName: "Redo timeline edit"
                toolTip: accessibleName
                enabled: WallpaperTimelineService.canRedo
                onActivated: {
                    root.forceActiveFocus();
                    root.redoRequested();
                }
            }

            GlyphButton {
                id: addTrackButton

                implicitWidth: 25
                implicitHeight: 25
                glyph: "plus"
                accessibleName: "Add timeline track"
                toolTip: "Add track"
                onActivated: trackMenu.openFor(addTrackButton, width / 2, height)
            }

            Text {
                text: projectDurationMs > 0 ? Ruler.label(playheadMs, 1000) + " / " + Ruler.label(projectDurationMs, 1000) : "Draft span · 0:10"
                color: Design.textMuted
                font.family: Design.fontMono
                font.pixelSize: 9
            }

            Rectangle {
                implicitWidth: zoomLabel.implicitWidth + 14
                implicitHeight: 22
                radius: 8
                color: Qt.rgba(1, 1, 1, 0.05)

                Text {
                    id: zoomLabel
                    anchors.centerIn: parent
                    text: Math.round(root.pixelsPerSecond) + " px/s"
                    color: Design.textMuted
                    font.family: Design.fontMono
                    font.pixelSize: 9
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
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

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true
                    onPressed: mouse => {
                        root.scrubbing = true;
                        root.scrubStarted();
                        root.playheadMs = Viewport.viewportXToTime(root.viewport, mouse.x);
                    }
                    onPositionChanged: mouse => {
                        if (root.scrubbing)
                            root.playheadMs = Viewport.viewportXToTime(root.viewport, mouse.x);
                    }
                    onReleased: {
                        if (root.scrubbing)
                            root.scrubFinished();
                        root.scrubbing = false;
                    }
                    onCanceled: root.scrubbing = false
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: trackList
                anchors.fill: parent
                clip: true
                reuseItems: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.project?.tracks || []
                spacing: 3

                delegate: Rectangle {
                    id: trackLane
                    required property var modelData
                    readonly property var trackData: modelData
                    width: ListView.view.width
                    height: 42
                    color: Qt.rgba(1, 1, 1, 0.018)

                    Rectangle {
                        id: trackHeader

                        width: root.viewportOriginX
                        height: parent.height
                        color: Qt.rgba(1, 1, 1, 0.022)

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 20
                            spacing: 1

                            Text {
                                width: parent.width
                                text: trackLane.trackData.name
                                color: Design.text
                                elide: Text.ElideRight
                                font.family: Design.fontText
                                font.pixelSize: 10
                                font.weight: Font.Medium
                            }
                            Text {
                                width: parent.width
                                text: trackLane.trackData.type
                                color: Design.textMuted
                                elide: Text.ElideRight
                                font.family: Design.fontText
                                font.pixelSize: 8
                            }
                        }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: {
                                root.forceActiveFocus();
                                WallpaperTimelineService.clearSelection();
                            }
                        }
                        TapHandler {
                            acceptedButtons: Qt.RightButton
                            onTapped: eventPoint => {
                                root.forceActiveFocus();
                                trackRemovalMenu.openFor(trackLane.trackData.id, trackHeader, eventPoint.position.x, eventPoint.position.y);
                            }
                        }
                    }

                    Item {
                        x: root.viewportOriginX
                        width: root.viewportWidth
                        height: parent.height
                        clip: true

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            propagateComposedEvents: true
                            onDoubleClicked: mouse => {
                                root.forceActiveFocus();
                                root.playheadMs = Viewport.viewportXToTime(root.viewport, mouse.x);
                            }
                        }

                        Repeater {
                            model: root.rulerData.ticks.filter(tick => tick.major)
                            delegate: Rectangle {
                                required property var modelData
                                x: modelData.x
                                width: 1
                                height: parent.height
                                color: Design.separator
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
                                readonly property var timelineRoot: root

                                x: Viewport.timeToViewportX(root.viewport, visibleClip.startMs)
                                y: 4
                                width: Math.max(12, visibleClip.durationMs * root.viewport.pixelsPerSecond / 1000)
                                height: parent.height - 8
                                clipData: timelineClip
                                assetData: timelineAsset
                                selected: WallpaperTimelineService.selection.clipIds.indexOf(timelineClip.id) >= 0
                                onActivated: modifiers => {
                                    root.forceActiveFocus();
                                    WallpaperTimelineService.selectClip(trackLane.trackData.id, timelineClip.id, root.selectionMode(modifiers));
                                }
                                onDoubleActivated: (localX, modifiers) => {
                                    root.forceActiveFocus();
                                    root.playheadMs = Viewport.viewportXToTime(root.viewport, clipItem.x + localX);
                                }
                                onContextRequested: (localX, localY, modifiers) => {
                                    root.forceActiveFocus();
                                    if (WallpaperTimelineService.selection.clipIds.indexOf(timelineClip.id) < 0)
                                        WallpaperTimelineService.selectClip(trackLane.trackData.id, timelineClip.id, root.selectionMode(modifiers));
                                    clipMenu.openFor(clipItem, localX, localY);
                                }
                                onGestureStarted: (mode, localX) => {
                                    root.forceActiveFocus();
                                    root.scrubbing = true;
                                    root.scrubStarted();
                                    const x = clipItem.mapToItem(root, localX, 0).x - root.viewportOriginX;
                                    WallpaperTimelineService.beginGesture(mode, timelineClip.id, trackLane.trackData.id, x, root.viewport.pixelsPerSecond, 8, timelineAsset?.media?.durationMs || 0);
                                }
                                onGestureMoved: localX => {
                                    const x = clipItem.mapToItem(root, localX, 0).x - root.viewportOriginX;
                                    WallpaperTimelineService.updateGesture(x, root.snappingEnabled);
                                }
                                onGestureFinished: {
                                    if (WallpaperTimelineService.gestureActive)
                                        WallpaperTimelineService.finishGesture();
                                    clipItem.timelineRoot.scrubbing = false;
                                }
                                onGestureCanceled: {
                                    if (WallpaperTimelineService.gestureActive)
                                        WallpaperTimelineService.cancelGesture();
                                    clipItem.timelineRoot.scrubbing = false;
                                }
                            }
                        }

                        DropArea {
                            anchors.fill: parent
                            keys: ["wallpaper-editor-media"]
                            onEntered: drag => {
                                drag.accepted = root.trackAcceptsDrag(trackLane.trackData, drag.source);
                                if (drag.accepted)
                                    root.updateDropPreview(trackLane.trackData.id, drag.x, drag.source);
                            }
                            onPositionChanged: drag => {
                                if (root.trackAcceptsDrag(trackLane.trackData, drag.source))
                                    root.updateDropPreview(trackLane.trackData.id, drag.x, drag.source);
                            }
                            onExited: root.clearDropPreview()
                            onDropped: drop => {
                                if (root.trackAcceptsDrag(trackLane.trackData, drop.source) && root.commitDrop(trackLane.trackData.id, drop.x, drop.source))
                                    drop.acceptProposedAction();
                            }
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
                        root.updateDropPreview("", drag.x - root.viewportOriginX, drag.source);
                }
                onPositionChanged: drag => root.updateDropPreview("", drag.x - root.viewportOriginX, drag.source)
                onExited: root.clearDropPreview()
                onDropped: drop => {
                    if (root.commitDrop("", drop.x - root.viewportOriginX, drop.source))
                        drop.acceptProposedAction();
                }
            }

            Column {
                anchors.centerIn: parent
                visible: trackList.count === 0
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No tracks yet"
                    color: Design.text
                    font.family: Design.fontText
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "The timeline is ready for your first media track."
                    color: Design.textMuted
                    font.family: Design.fontText
                    font.pixelSize: 9
                }
            }
        }
    }

    Rectangle {
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
            x: -6
            width: 13
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            cursorShape: Qt.SizeHorCursor
            onPressed: mouse => {
                root.forceActiveFocus();
                root.scrubbing = true;
                root.scrubStarted();
                root.playheadMs = Viewport.viewportXToTime(root.viewport, playheadDragArea.mapToItem(root, mouse.x, 0).x - root.viewportOriginX);
            }
            onPositionChanged: mouse => {
                if (root.scrubbing)
                    root.playheadMs = Viewport.viewportXToTime(root.viewport, playheadDragArea.mapToItem(root, mouse.x, 0).x - root.viewportOriginX);
            }
            onReleased: {
                if (root.scrubbing)
                    root.scrubFinished();
                root.scrubbing = false;
            }
            onCanceled: root.scrubbing = false
        }
    }

    Rectangle {
        visible: root.previewLooping && root.loopEndMs > root.loopStartMs && root.loopEndX > 0 && root.loopStartX < root.viewportWidth
        x: root.viewportOriginX + root.visibleLoopStartX
        y: 42
        width: Math.max(1, root.visibleLoopEndX - root.visibleLoopStartX)
        height: 3
        radius: 1.5
        color: Qt.rgba(Design.blue.r, Design.blue.g, Design.blue.b, 0.48)
        z: 2
    }

    Repeater {
        model: root.previewLooping ? ["start", "end"] : []
        delegate: Rectangle {
            required property string modelData
            readonly property bool startHandle: modelData === "start"
            readonly property real handleX: startHandle ? root.loopStartX : root.loopEndX
            x: root.viewportOriginX + (startHandle ? root.loopStartX : root.loopEndX) - width / 2
            y: 36
            width: 5
            height: 15
            visible: root.previewLooping && handleX >= 0 && handleX <= root.viewportWidth
            color: Qt.rgba(Design.blue.r, Design.blue.g, Design.blue.b, 0.86)
            radius: 4
            z: 8

            MouseArea {
                id: loopHandleDrag
                anchors.fill: parent
                anchors.margins: -5
                acceptedButtons: Qt.LeftButton
                preventStealing: true
                cursorShape: Qt.SizeHorCursor
                onPressed: mouse => {
                    root.forceActiveFocus();
                    root.scrubbing = true;
                    root.scrubStarted();
                }
                onPositionChanged: mouse => {
                    if (!root.scrubbing)
                        return;
                    const localX = loopHandleDrag.mapToItem(root, mouse.x, 0).x - root.viewportOriginX;
                    const time = Viewport.viewportXToTime(root.viewport, localX);
                    if (startHandle)
                        root.loopStartMs = Math.min(time, root.loopEndMs - 1);
                    else
                        root.loopEndMs = Math.max(time, root.loopStartMs + 1);
                    root.loopRegionChanged(root.loopStartMs, root.loopEndMs);
                }
                onReleased: {
                    if (root.scrubbing)
                        root.scrubFinished();
                    root.scrubbing = false;
                }
                onCanceled: root.scrubbing = false
            }
        }
    }

    Rectangle {
        visible: root.dropPreviewVisible
        x: root.viewportOriginX + Viewport.timeToViewportX(root.viewport, root.dropPreviewTimeMs)
        y: 72 + (root.dropPreviewTrackId.length > 0 ? Math.max(0, (root.project?.tracks || []).findIndex(track => track.id === root.dropPreviewTrackId)) * 45 + 4 : 12)
        width: Math.max(14, Math.min(root.viewportWidth, root.dropPreviewDurationMs * root.viewport.pixelsPerSecond / 1000))
        height: 34
        radius: 8
        color: Qt.rgba(Design.blue.r, Design.blue.g, Design.blue.b, 0.2)
        border.width: 1
        border.color: Design.blue
        opacity: 0.78
        z: 6

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 3
            radius: 1.5
            color: Design.blue
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
            color: Qt.rgba(1, 1, 1, 0.035)
        }

        Rectangle {
            id: overviewThumb
            x: root.viewport.maximumScrollX > 0 ? root.scrollX / root.viewport.maximumScrollX * Math.max(0, parent.width - overviewThumb.width) : 0
            width: Math.max(28, parent.width * parent.width / Math.max(parent.width, root.viewport.contentWidth))
            height: parent.height
            radius: 2
            color: Qt.rgba(Design.blue.r, Design.blue.g, Design.blue.b, 0.58)
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
