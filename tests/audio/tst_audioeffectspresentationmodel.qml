import QtQuick
import QtTest
import "../../services/audio/AudioEffectsPresentationModel.js" as AudioEffectsPresentationModel

TestCase {
    name: "AudioEffectsPresentationModel"

    function effects() {
        return {
            loaded: true,
            state: "ready",
            busy: false,
            capability: {
                installed: true,
                running: true
            },
            output: {
                presets: ["Voice", "Music", "Music", ""],
                activePreset: "Music",
                activePresetKnown: true
            },
            input: {
                presets: ["Meeting"],
                activePreset: "",
                activePresetKnown: true
            }
        };
    }

    function test_rowsAreNormalizedSortedAndActive() {
        const rows = AudioEffectsPresentationModel.rows(effects(), "output");
        compare(rows.length, 2);
        compare(rows[0].name, "Music");
        verify(rows[0].active);
        compare(rows[1].name, "Voice");
        verify(!rows[1].active);
    }

    function test_selectionPrefersStableThenActiveThenFirst() {
        const rows = AudioEffectsPresentationModel.rows(effects(), "output");
        compare(AudioEffectsPresentationModel.selectionAfterChange(rows, "Voice"), "Voice");
        compare(AudioEffectsPresentationModel.selectionAfterChange(rows, "Missing"), "Music");
        compare(AudioEffectsPresentationModel.movedSelection(rows, "Music", 1), "Voice");
        compare(AudioEffectsPresentationModel.movedSelection(rows, "Voice", 1), "Voice");
    }

    function test_readinessRequiresConfirmedRunningProvider() {
        const value = effects();
        verify(AudioEffectsPresentationModel.controlsReady(value));
        value.busy = true;
        verify(!AudioEffectsPresentationModel.controlsReady(value));
        value.busy = false;
        value.capability.running = false;
        verify(!AudioEffectsPresentationModel.controlsReady(value));
    }

    function test_emptyMessagesRemainTruthful() {
        compare(AudioEffectsPresentationModel.emptyMessage({}, "output"), "Discovering presets…");
        const absent = effects();
        absent.capability.installed = false;
        absent.capability.running = false;
        compare(AudioEffectsPresentationModel.emptyMessage(absent, "output"), "EasyEffects is not installed");
        const stopped = effects();
        stopped.capability.running = false;
        compare(AudioEffectsPresentationModel.emptyMessage(stopped, "input"), "Open EasyEffects to use presets");
        compare(AudioEffectsPresentationModel.emptyMessage(effects(), "input"), "No input presets found");
    }
}
