import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import "../services/wallpaper/projects/WallpaperTimelineRuler.js" as Ruler

Item {
    id: root

    required property int projectDurationMs
    required property int playheadMs
    required property real pixelsPerSecond
    required property bool previewPlaying
    required property bool previewLooping
    required property bool canUndo
    required property bool canRedo

    signal focusRequested
    signal previewPlayPauseRequested
    signal previewLoopRequested
    signal undoRequested
    signal redoRequested
    signal addTrackRequested(Item source, real localX, real localY)

    implicitHeight: 38

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: "Timeline"
            color: Theme.textPrimary
            font.family: Design.fontText
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }

        GlyphButton {
            objectName: "timelinePlayPauseButton"
            implicitWidth: 25
            implicitHeight: 25
            glyph: root.previewPlaying ? "pause" : "play"
            accessibleName: root.previewPlaying ? "Pause preview" : "Play preview"
            toolTip: accessibleName
            enabled: root.projectDurationMs > 0
            primary: root.previewPlaying
            onActivated: {
                root.focusRequested();
                root.previewPlayPauseRequested();
            }
        }

        GlyphButton {
            objectName: "timelineLoopButton"
            implicitWidth: 25
            implicitHeight: 25
            glyph: "repeat"
            accessibleName: root.previewLooping ? "Disable preview loop" : "Enable preview loop"
            toolTip: accessibleName
            primary: root.previewLooping
            enabled: root.projectDurationMs > 0
            onActivated: {
                root.focusRequested();
                root.previewLoopRequested();
            }
        }

        GlyphButton {
            objectName: "timelineUndoButton"
            implicitWidth: 25
            implicitHeight: 25
            glyph: "undo"
            accessibleName: "Undo timeline edit"
            toolTip: accessibleName
            enabled: root.canUndo
            onActivated: {
                root.focusRequested();
                root.undoRequested();
            }
        }

        GlyphButton {
            objectName: "timelineRedoButton"
            implicitWidth: 25
            implicitHeight: 25
            glyph: "redo"
            accessibleName: "Redo timeline edit"
            toolTip: accessibleName
            enabled: root.canRedo
            onActivated: {
                root.focusRequested();
                root.redoRequested();
            }
        }

        GlyphButton {
            id: addTrackButton

            objectName: "timelineAddTrackButton"
            implicitWidth: 25
            implicitHeight: 25
            glyph: "plus"
            accessibleName: "Add timeline track"
            toolTip: "Add track"
            onActivated: {
                root.focusRequested();
                root.addTrackRequested(addTrackButton, width / 2, height);
            }
        }

        Text {
            text: root.projectDurationMs > 0 ? Ruler.label(root.playheadMs, 1000) + " / " + Ruler.label(root.projectDurationMs, 1000) : "Draft span · 0:10"
            color: Theme.textSecondary
            font.family: Design.fontMono
            font.pixelSize: 9
        }

        Rectangle {
            implicitWidth: zoomLabel.implicitWidth + 14
            implicitHeight: 22
            radius: 8
            color: Theme.fillSubtle

            Text {
                id: zoomLabel

                anchors.centerIn: parent
                text: Math.round(root.pixelsPerSecond) + " px/s"
                color: Theme.textSecondary
                font.family: Design.fontMono
                font.pixelSize: 9
            }
        }
    }
}
