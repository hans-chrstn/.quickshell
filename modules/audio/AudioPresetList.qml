import QtQuick
import QtQuick.Controls
import qs.components
import qs.components.scrolling
import qs.core
import "../../services/audio/AudioEffectsPresentationModel.js" as AudioEffectsPresentationModel

Item {
    id: root

    required property var effects
    required property string pipeline
    property string selectedPreset: ""
    signal selectionRequested(string preset)
    signal presetRequested(string pipeline, string preset)

    readonly property var rows: AudioEffectsPresentationModel.rows(effects, pipeline)
    readonly property real rowHeight: 50
    readonly property bool controlsReady: AudioEffectsPresentationModel.controlsReady(effects)

    function moveSelection(step) {
        const preset = AudioEffectsPresentationModel.movedSelection(rows, selectedPreset, step);
        if (preset.length === 0)
            return false;
        selectionRequested(preset);
        const index = AudioEffectsPresentationModel.indexForName(rows, preset);
        if (index >= 0)
            presetList.positionViewAtIndex(index, ListView.Contain);
        return true;
    }

    function selectBoundary(last) {
        if (rows.length === 0)
            return false;
        const index = last ? rows.length - 1 : 0;
        selectionRequested(rows[index].name);
        presetList.positionViewAtIndex(index, ListView.Contain);
        return true;
    }

    function activateSelected() {
        const index = AudioEffectsPresentationModel.indexForName(rows, selectedPreset);
        if (index < 0 || !controlsReady)
            return false;
        presetRequested(pipeline, rows[index].name);
        return true;
    }

    Text {
        anchors.centerIn: parent
        visible: root.rows.length === 0
        text: AudioEffectsPresentationModel.emptyMessage(root.effects, root.pipeline)
        color: Theme.textTertiary
        font.family: Design.fontText
        font.pixelSize: 11
    }

    ListView {
        id: presetList

        anchors.fill: parent
        anchors.rightMargin: 9
        visible: root.rows.length > 0
        clip: true
        model: root.rows
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        reuseItems: true
        ScrollBar.vertical: MinimalScrollBar {}

        SmoothScrollBehavior {
            target: presetList
            wheelStep: root.rowHeight
        }

        delegate: Item {
            id: row

            required property int index
            required property var modelData
            readonly property bool selected: root.selectedPreset === modelData.name
            readonly property bool applying: root.effects.busy === true && root.effects.operation?.kind === "preset" && root.effects.operation?.pipeline === root.pipeline && root.effects.operation?.preset === modelData.name

            width: presetList.width
            height: root.rowHeight

            HighlightableSurface {
                anchors.fill: parent
                selected: row.selected
                focused: row.applying
                interactive: root.controlsReady
                hoverEnabled: root.controlsReady
                accentColor: Theme.textSecondary
                baseColor: "transparent"
                cornerRadius: 14
                accessibleName: row.modelData.name + (row.modelData.active ? ", active" : "")
                onSurfaceActivated: {
                    root.selectionRequested(row.modelData.name);
                    if (!row.modelData.active)
                        root.presetRequested(root.pipeline, row.modelData.name);
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 34
                radius: 11
                color: row.modelData.active || row.selected ? Theme.fillStrong : Theme.fillSubtle

                IslandGlyph {
                    anchors.centerIn: parent
                    width: 19
                    height: 19
                    name: row.applying ? "repeat" : root.pipeline === "input" ? "microphone" : "volumeHigh"
                    glyphColor: row.modelData.active || row.selected ? Theme.textPrimary : Theme.textSecondary
                }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 54
                anchors.right: status.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.name
                color: Theme.textPrimary
                font.family: Design.fontText
                font.pixelSize: 13
                font.weight: row.modelData.active ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
            }

            Text {
                id: status

                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: row.applying ? "Applying…" : row.modelData.active ? "Active" : ""
                color: Theme.textSecondary
                font.family: Design.fontText
                font.pixelSize: 10
            }

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 54
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                visible: row.index < root.rows.length - 1
                color: Theme.separator
                opacity: 0.56
            }
        }
    }
}
