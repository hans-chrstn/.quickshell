import QtQuick
import QtQuick.Layouts
import qs.components
import qs.core
import qs.services.audio
import qs.services.notifications
import "../../services/audio/AudioEffectsPresentationModel.js" as AudioEffectsPresentationModel

Item {
    id: root

    property string pipeline: "output"
    property string selectedOutputPreset: ""
    property string selectedInputPreset: ""
    readonly property var effects: AudioService.effects
    readonly property var rows: AudioEffectsPresentationModel.rows(effects, pipeline)
    readonly property string selectedPreset: pipeline === "input" ? selectedInputPreset : selectedOutputPreset
    readonly property bool controlsReady: AudioEffectsPresentationModel.controlsReady(effects)
    readonly property bool effectsEnabled: effects.bypassKnown === true && effects.bypassed !== true

    implicitWidth: 600
    implicitHeight: 300

    function setSelectedPreset(preset) {
        if (pipeline === "input")
            selectedInputPreset = preset;
        else
            selectedOutputPreset = preset;
    }

    function requestPreset(targetPipeline, preset) {
        if (!controlsReady)
            return false;
        const result = AudioService.loadEffectsPreset(targetPipeline, preset);
        if (!result.accepted)
            NotificationService.showError("Preset could not be applied", result.message, AudioPanelService.targetScreenName, "audio-effects-preset", "Sound");
        return result.accepted === true;
    }

    function requestEnabled(enabled) {
        if (!controlsReady)
            return false;
        const result = AudioService.setEffectsBypassed(!enabled);
        if (!result.accepted)
            NotificationService.showError("Effects could not be changed", result.message, AudioPanelService.targetScreenName, "audio-effects-bypass", "Sound");
        return result.accepted === true;
    }

    function selectPipeline(value) {
        const next = value === "input" ? "input" : "output";
        if (pipeline === next)
            return false;
        pipeline = next;
        return true;
    }

    function handleEscape() {
        return false;
    }

    function handleNavigation(key, modifiers) {
        if (key === Qt.Key_Left)
            return selectPipeline("output");
        if (key === Qt.Key_Right)
            return selectPipeline("input");
        if (key === Qt.Key_Up)
            return presetList.moveSelection(-1);
        if (key === Qt.Key_Down)
            return presetList.moveSelection(1);
        if (key === Qt.Key_Home)
            return presetList.selectBoundary(false);
        if (key === Qt.Key_End)
            return presetList.selectBoundary(true);
        if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space)
            return presetList.activateSelected();
        return false;
    }

    onRowsChanged: setSelectedPreset(AudioEffectsPresentationModel.selectionAfterChange(rows, selectedPreset))

    Connections {
        target: EasyEffectsService

        function onResultOccurred(result) {
            if (result?.accepted === false)
                NotificationService.showError("Effects request failed", String(result?.message || "EasyEffects did not confirm the change."), AudioPanelService.targetScreenName, "audio-effects-result", "Sound");
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: Theme.fillSubtle
        border.width: 1
        border.color: Theme.separatorQuiet

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.preferredHeight: 42
                spacing: 11

                IslandGlyph {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    name: "effects"
                    glyphColor: Theme.textPrimary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: "EasyEffects"
                        color: Theme.textPrimary
                        font.family: Design.fontText
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: !root.effects.loaded || ["idle", "discovering"].includes(root.effects.state) ? "Discovering…" : !root.effects.capability?.installed ? "Not installed" : !root.effects.capability?.running ? "Not running" : root.effectsEnabled ? "Processing audio" : "Bypassed"
                        color: Theme.textSecondary
                        font.family: Design.fontText
                        font.pixelSize: 10
                    }
                }

                Text {
                    text: root.effectsEnabled ? "On" : "Off"
                    color: root.controlsReady ? Theme.textSecondary : Theme.textTertiary
                    font.family: Design.fontText
                    font.pixelSize: 10
                }

                ToggleSwitch {
                    checked: root.effectsEnabled
                    enabled: root.controlsReady && root.effects.bypassKnown === true
                    activeColor: Theme.selection
                    accessibleName: "EasyEffects processing"
                    onToggled: checked => root.requestEnabled(checked)
                }
            }

            SegmentedPageBar {
                Layout.preferredWidth: 210
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignHCenter
                controlHeight: 32
                cornerRadius: 11
                labelPixelSize: 10
                accentColor: Theme.textSecondary
                pages: [
                    {
                        id: "output",
                        label: "Output"
                    },
                    {
                        id: "input",
                        label: "Input"
                    }
                ]
                currentPage: root.pipeline
                onPageSelected: pageId => root.selectPipeline(pageId)
            }

            AudioPresetList {
                id: presetList

                Layout.fillWidth: true
                Layout.fillHeight: true
                effects: root.effects
                pipeline: root.pipeline
                selectedPreset: root.selectedPreset
                onSelectionRequested: preset => root.setSelectedPreset(preset)
                onPresetRequested: (targetPipeline, preset) => root.requestPreset(targetPipeline, preset)
            }
        }
    }
}
