import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.filepicker
import qs.components.layout
import qs.core
import qs.editor
import qs.services.config
import qs.services.wallpaper.projects
import "WallpaperEditorLayout.js" as EditorLayout

Rectangle {
    id: root

    property bool embeddedInIsland: false
    property var horizontalWeights: ConfigService.editorHorizontalSplitWeights.slice()
    property var verticalWeights: ConfigService.editorVerticalSplitWeights.slice()
    property var mediaPreviewDragBase: null
    property var timelineDragBase: null

    function commitLayoutPreferences() {
        ConfigService.setEditorLayoutPreferences(horizontalWeights, verticalWeights);
    }

    focus: true
    Component.onCompleted: forceActiveFocus()

    readonly property bool compact: width < 980
    readonly property var editorLayout: EditorLayout.resolve({
        width: width,
        height: height,
        horizontalWeights: horizontalWeights,
        verticalWeights: verticalWeights,
        policy: {
            outerMargin: 10,
            gap: Design.editorGap,
            headerHeight: 42,
            compactThreshold: 980
        }
    })

    radius: embeddedInIsland ? 0 : Design.editorPanelRadius
    color: embeddedInIsland ? "transparent" : Design.islandExpanded
    border.width: embeddedInIsland ? 0 : 1
    border.color: embeddedInIsland ? "transparent" : Design.glassStroke
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: Design.editorGap

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            Layout.leftMargin: 8
            Layout.rightMargin: 2
            spacing: 9

            Rectangle {
                implicitWidth: 25
                implicitHeight: 25
                radius: 8
                color: Qt.rgba(Design.blue.r, Design.blue.g, Design.blue.b, 0.18)

                Text {
                    anchors.centerIn: parent
                    text: "W"
                    color: Design.blue
                    font.family: Design.fontDisplay
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: WallpaperEditorService.projectName
                    color: Design.text
                    font.family: Design.fontDisplay
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: "Wallpaper Studio"
                    color: Design.textMuted
                    font.family: Design.fontText
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                implicitWidth: statusText.implicitWidth + 18
                implicitHeight: 25
                radius: 9
                color: Qt.rgba(1, 1, 1, 0.045)
                Text {
                    id: statusText
                    anchors.centerIn: parent
                    text: WallpaperProjectService.dirty ? "Unsaved" : "Saved"
                    color: WallpaperProjectService.dirty ? Design.yellow : Design.textMuted
                    font.family: Design.fontText
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }
            }

            PickerButton {
                label: "Save As"
                enabled: WallpaperEditorService.workspaceId.length > 0 && !WallpaperEditorService.importBusy
                onActivated: WallpaperEditorService.openSaveAs()
            }

            GlyphButton {
                glyph: "folder"
                accessibleName: "Open Project"
                enabled: !WallpaperEditorService.importBusy && !WallpaperEditorService.openProjectBusy
                onActivated: WallpaperEditorService.openProjectPicker()
            }

            EditorIconButton {
                accessibleName: "Close editor"
                enabled: !WallpaperEditorService.openProjectBusy
                onClicked: WallpaperEditorService.close()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.editorLayout.upperHeight
            Layout.minimumHeight: 220

            EditorMediaLibrary {
                x: 0
                width: root.editorLayout.mediaWidth
                height: parent.height
            }

            WallpaperProjectPreview {
                id: projectPreview
                x: root.editorLayout.mediaWidth + Design.editorGap
                width: root.editorLayout.previewWidth
                height: parent.height
                projectPlan: {
                    const project = WallpaperEditorService.activeProject;
                    return WallpaperProjectAvailabilityService.runtimePlan(project).plan;
                }
                screenName: WallpaperEditorService.targetScreenName
                positionMs: timeline.playheadMs
                scrubbing: timeline.scrubbing
            }

            Connections {
                target: projectPreview
                function onPreviewPositionMsChanged() {
                    if (projectPreview.playing)
                        timeline.playheadMs = projectPreview.previewPositionMs;
                }
                function onLoopStartMsChanged() {
                    timeline.loopStartMs = projectPreview.loopStartMs;
                }
                function onLoopEndMsChanged() {
                    timeline.loopEndMs = projectPreview.loopEndMs;
                }
            }

            EditorRegion {
                x: root.editorLayout.mediaWidth + root.editorLayout.previewWidth + Design.editorGap * 2
                width: root.editorLayout.inspectorWidth
                height: parent.height
                title: WallpaperEditorService.selectedAsset ? WallpaperEditorService.selectedAsset.name : "Inspector"
                description: WallpaperEditorService.selectedAsset ? (WallpaperEditorService.selectedAsset.state === "available" ? WallpaperEditorService.selectedAsset.declaredKind : WallpaperEditorService.selectedAsset.state) : "Select an asset or timeline item to edit its properties."
                glyph: "···"
            }

            SplitHandle {
                x: root.editorLayout.mediaWidth
                y: 0
                width: Design.editorGap
                height: parent.height
                z: 4
                onDragStarted: root.mediaPreviewDragBase = root.editorLayout
                onDragged: delta => {
                    if (!root.mediaPreviewDragBase)
                        return;
                    const result = EditorLayout.dragHorizontal(root.mediaPreviewDragBase, 0, delta);
                    if (result.accepted)
                        root.horizontalWeights = result.layout.horizontal.extraWeights;
                }
                onDragFinished: {
                    root.mediaPreviewDragBase = null;
                    root.commitLayoutPreferences();
                }
            }

            SplitHandle {
                x: root.editorLayout.mediaWidth + root.editorLayout.previewWidth + Design.editorGap
                y: 0
                width: Design.editorGap
                height: parent.height
                z: 4
                onDragStarted: root.mediaPreviewDragBase = root.editorLayout
                onDragged: delta => {
                    if (!root.mediaPreviewDragBase)
                        return;
                    const result = EditorLayout.dragHorizontal(root.mediaPreviewDragBase, 1, delta);
                    if (result.accepted)
                        root.horizontalWeights = result.layout.horizontal.extraWeights;
                }
                onDragFinished: {
                    root.mediaPreviewDragBase = null;
                    root.commitLayoutPreferences();
                }
            }
        }

        EditorTimeline {
            id: timeline
            Layout.fillWidth: true
            Layout.preferredHeight: root.editorLayout.timelineHeight
            previewPlaying: projectPreview.playing
            previewLooping: projectPreview.loopEnabled
            loopStartMs: projectPreview.loopStartMs
            loopEndMs: projectPreview.loopEndMs
            onPreviewPlayPauseRequested: projectPreview.togglePlayback()
            onPreviewLoopRequested: projectPreview.toggleLoop()
            onLoopRegionChanged: (startMs, endMs) => projectPreview.setLoopRegion(startMs, endMs)
            onUndoRequested: WallpaperTimelineService.undo()
            onRedoRequested: WallpaperTimelineService.redo()
            onScrubStarted: projectPreview.pausePreview()
        }
    }

    SplitHandle {
        vertical: true
        x: 10
        y: 10 + 42 + Design.editorGap + root.editorLayout.upperHeight
        width: Math.max(0, root.width - 20)
        height: Design.editorGap
        z: 4
        onDragStarted: root.timelineDragBase = root.editorLayout
        onDragged: delta => {
            if (!root.timelineDragBase)
                return;
            const result = EditorLayout.dragVertical(root.timelineDragBase, delta);
            if (result.accepted)
                root.verticalWeights = result.layout.vertical.extraWeights;
        }
        onDragFinished: {
            root.timelineDragBase = null;
            root.commitLayoutPreferences();
        }
    }

    Loader {
        anchors.fill: parent
        anchors.margins: 10
        z: 50
        active: WallpaperEditorService.pickerOpened
        source: Qt.resolvedUrl("EditorMediaPicker.qml")
    }

    Loader {
        anchors.fill: parent
        anchors.margins: 10
        z: 53
        active: WallpaperEditorOpenService.pickerOpened
        source: Qt.resolvedUrl("EditorOpenProjectPicker.qml")
    }

    Loader {
        anchors.fill: parent
        anchors.margins: 10
        z: 51
        active: WallpaperEditorService.saveAsOpened
        source: Qt.resolvedUrl("EditorSaveAsPanel.qml")
    }
}
