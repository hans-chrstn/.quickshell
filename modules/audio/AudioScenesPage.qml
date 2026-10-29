import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.menus
import qs.core
import qs.services
import qs.services.audio
import qs.services.notifications
import "../../services/audio/AudioScenePresentationModel.js" as AudioScenePresentationModel

Item {
    id: root

    property string selectedSceneId: ""
    property string resultSceneId: ""
    property string resultCode: ""
    property string removeSceneId: ""
    property string removeSceneName: ""
    readonly property var rows: AudioScenePresentationModel.rows(AudioService.scenes)
    readonly property bool dependenciesSettled: AudioService.inventoryLoaded && EasyEffectsService.loaded && !AudioService.effects.busy && !["idle", "discovering"].includes(AudioService.effects.state)

    implicitWidth: 600
    implicitHeight: 300

    function handleEscape() {
        return false;
    }

    function handleNavigation(key, modifiers) {
        if (key === Qt.Key_Up)
            return sceneList.moveSelection(-1);
        if (key === Qt.Key_Down)
            return sceneList.moveSelection(1);
        if (key === Qt.Key_Home)
            return sceneList.selectBoundary(false);
        if (key === Qt.Key_End)
            return sceneList.selectBoundary(true);
        if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space)
            return requestActivation(selectedSceneId);
        if (key === Qt.Key_Delete)
            return sceneList.removeSelected();
        return false;
    }

    function selectScene(sceneId) {
        selectedSceneId = String(sceneId || "");
    }

    function requestActivation(sceneId) {
        const id = String(sceneId || "");
        if (id.length === 0 || AudioService.sceneActivationBusy)
            return false;
        selectedSceneId = id;
        resultSceneId = "";
        resultCode = "";
        const result = AudioService.activateAudioScene(id);
        if (!result.accepted) {
            resultSceneId = id;
            resultCode = "failed";
            NotificationService.showError("Scene could not be applied", result.message, AudioPanelService.targetScreenName, "audio-scene-apply", "Sound");
            resultTimer.restart();
        }
        return true;
    }

    function requestRemoval(sceneId, sceneName) {
        removeSceneId = String(sceneId || "");
        removeSceneName = String(sceneName || "Audio scene");
        removeConfirmation.open();
    }

    onRowsChanged: selectedSceneId = AudioScenePresentationModel.selectionAfterChange(rows, selectedSceneId)

    Connections {
        target: AudioService

        function onSceneResultOccurred(result) {
            root.resultSceneId = String(result?.sceneId || "");
            root.resultCode = result?.accepted === true ? String(result?.code || "completed") : "failed";
            if (result?.accepted !== true)
                NotificationService.showError("Scene could not be applied", String(result?.message || "The sound setup could not be restored."), AudioPanelService.targetScreenName, "audio-scene-apply", "Sound");
            resultTimer.restart();
        }
    }

    Timer {
        id: resultTimer

        interval: 2600
        onTriggered: {
            root.resultSceneId = "";
            root.resultCode = "";
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
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                Layout.preferredHeight: 42
                spacing: 11

                IslandGlyph {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    name: "repeat"
                    glyphColor: Theme.textPrimary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: "Audio Scenes"
                        color: Theme.textPrimary
                        font.family: Design.fontText
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.rows.length + (root.rows.length === 1 ? " saved setup" : " saved setups")
                        color: Theme.textSecondary
                        font.family: Design.fontText
                        font.pixelSize: 10
                    }
                }

                GlyphButton {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    glyph: "plus"
                    glyphSize: 17
                    primary: true
                    accentColor: Theme.textSecondary
                    enabled: root.dependenciesSettled && root.rows.length < 32 && !AudioService.sceneActivationBusy
                    accessibleName: "Save current audio scene"
                    toolTip: enabled ? "Save current setup" : "Preparing current sound setup"
                    onActivated: captureDialog.openWith("")
                }
            }

            AudioSceneList {
                id: sceneList

                Layout.fillWidth: true
                Layout.fillHeight: true
                scenes: AudioService.scenes
                selectedSceneId: root.selectedSceneId
                busySceneId: AudioService.sceneActivationSceneId
                resultSceneId: root.resultSceneId
                resultCode: root.resultCode
                onSelectionRequested: sceneId => root.selectScene(sceneId)
                onSceneRequested: sceneId => root.requestActivation(sceneId)
                onRemoveRequested: (sceneId, sceneName) => root.requestRemoval(sceneId, sceneName)
            }
        }
    }

    TextEntryDialog {
        id: captureDialog

        title: "Save Audio Scene"
        message: "Capture the current devices, effects, and safe volume levels."
        fieldLabel: "Scene name"
        placeholderText: "Night, Meeting, Studio…"
        maximumLength: 64
        confirmLabel: "Save"
        validator: value => value.trim().length > 0 ? "" : "Enter a scene name."
        submitHandler: value => {
            const result = AudioService.captureAudioScene(value);
            if (result.accepted) {
                root.selectedSceneId = String(result.scene?.id || "");
                root.resultSceneId = root.selectedSceneId;
                root.resultCode = "unchanged";
                resultTimer.restart();
            }
            return result;
        }
    }

    ConfirmationDialog {
        id: removeConfirmation

        title: "Remove Audio Scene?"
        message: "“" + root.removeSceneName + "” will be removed. Audio devices and effects will not be changed."
        confirmLabel: "Remove"
        destructive: true
        onAccepted: {
            const result = AudioService.removeAudioScene(root.removeSceneId);
            if (!result.accepted)
                NotificationService.showError("Scene could not be removed", result.message, AudioPanelService.targetScreenName, "audio-scene-remove", "Sound");
            root.removeSceneId = "";
            root.removeSceneName = "";
        }
        onRejected: {
            root.removeSceneId = "";
            root.removeSceneName = "";
        }
    }
}
