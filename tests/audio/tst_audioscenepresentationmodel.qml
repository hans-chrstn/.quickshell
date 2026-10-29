import QtQuick
import QtTest
import "../../services/audio/AudioScenePresentationModel.js" as AudioScenePresentationModel

TestCase {
    name: "AudioScenePresentationModel"

    readonly property var scenes: [
        {
            id: "studio",
            name: "Studio",
            outputPreset: "Music",
            inputPreset: "Voice",
            outputCeiling: 0.8,
            inputCeiling: 0.55
        },
        {
            id: "night",
            name: "Night",
            outputPreset: "",
            inputPreset: "",
            outputCeiling: null,
            inputCeiling: null
        }
    ]

    function test_rowsPresentBoundedUsefulSummary() {
        const rows = AudioScenePresentationModel.rows(scenes);
        compare(rows.length, 2);
        compare(rows[0].id, "studio");
        compare(rows[0].summary, "Music output  ·  Voice input  ·  80% / 55%");
        compare(rows[1].summary, "Saved devices");
    }

    function test_selectionReconcilesAndMovesByStableIdentity() {
        const rows = AudioScenePresentationModel.rows(scenes);
        compare(AudioScenePresentationModel.selectionAfterChange(rows, "night"), "night");
        compare(AudioScenePresentationModel.selectionAfterChange(rows, "missing"), "studio");
        compare(AudioScenePresentationModel.movedSelection(rows, "studio", 1), "night");
        compare(AudioScenePresentationModel.movedSelection(rows, "night", 1), "night");
        compare(AudioScenePresentationModel.movedSelection(rows, "studio", -1), "studio");
    }

    function test_emptyInputHasNoSyntheticSelection() {
        compare(AudioScenePresentationModel.rows(null), []);
        compare(AudioScenePresentationModel.selectionAfterChange([], "studio"), "");
        compare(AudioScenePresentationModel.movedSelection([], "studio", 1), "");
    }
}
