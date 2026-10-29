import QtQuick
import QtTest
import "../../services/audio/AudioSceneModel.js" as AudioSceneModel

TestCase {
    name: "AudioSceneModel"

    function device(role, key, ready) {
        return {
            role: role + "-device",
            stableKey: role + "-device:" + key,
            ready: ready !== false
        };
    }

    function context() {
        return {
            nodes: [device("output", "speakers"), device("input", "microphone")],
            defaultOutput: device("output", "speakers"),
            defaultInput: device("input", "microphone"),
            output: {
                available: true,
                volume: 0.8
            },
            input: {
                available: true,
                volume: 0.6
            },
            effects: {
                state: "ready",
                output: {
                    presets: ["Music"],
                    activePreset: "Music",
                    activePresetKnown: true
                },
                input: {
                    presets: ["Voice"],
                    activePreset: "Voice",
                    activePresetKnown: true
                }
            }
        };
    }

    function test_captureStoresReferencesAndSafeCeilingsOnly() {
        const captured = AudioSceneModel.capture("Studio", context(), [], "1");
        verify(captured.accepted);
        compare(captured.scene, {
            id: "studio",
            name: "Studio",
            outputPreset: "Music",
            inputPreset: "Voice",
            outputDeviceKey: "output-device:speakers",
            inputDeviceKey: "input-device:microphone",
            outputCeiling: 0.8,
            inputCeiling: 0.6
        });
        verify(!JSON.stringify(captured.scene).includes("presetContents"));
    }

    function test_captureOmitsAnActivePresetMissingFromInventory() {
        const current = context();
        current.effects.input.presets = [];
        const captured = AudioSceneModel.capture("Portable", current, [], "1");
        verify(captured.accepted);
        compare(captured.scene.outputPreset, "Music");
        compare(captured.scene.inputPreset, "");
    }

    function test_captureUsesStableUniqueIdsAndBoundsNames() {
        const first = AudioSceneModel.capture("Night", context(), [], "1");
        const second = AudioSceneModel.capture("Night", context(), first.scenes, "2");
        compare(first.scene.id, "night");
        compare(second.scene.id, "night-2");
        compare(AudioSceneModel.capture("x".repeat(65), context(), [], "1").code, "name-too-long");
        compare(AudioSceneModel.capture("", context(), [], "1").code, "invalid-name");
    }

    function test_normalizationRejectsUnsafeReferencesAndDuplicates() {
        const scenes = AudioSceneModel.normalizedScenes([
            {
                id: " Scene ",
                name: "  My   Scene ",
                outputPreset: "bad:name",
                outputDeviceKey: "specialized-node:easyeffects_sink",
                outputCeiling: 99
            },
            {
                id: "scene",
                name: "Duplicate"
            }
        ]);
        compare(scenes.length, 1);
        compare(scenes[0].name, "My Scene");
        compare(scenes[0].outputPreset, "");
        compare(scenes[0].outputDeviceKey, "");
        compare(scenes[0].outputCeiling, 1.5);
        compare(AudioSceneModel.normalizedScenes({
            id: "not-an-array"
        }), []);
        compare(AudioSceneModel.normalizedScene({
            id: "silent",
            name: "Silent",
            outputCeiling: 0
        }).outputCeiling, 0);
        compare(AudioSceneModel.sceneForId(scenes, "scene"), scenes[0]);
        compare(AudioSceneModel.sceneForId(scenes, "missing"), null);
    }

    function test_applyPlanIsAtomicAndNeverRaisesGain() {
        const captured = AudioSceneModel.capture("Studio", context(), [], "1").scene;
        const louder = context();
        louder.defaultOutput = device("output", "other-speakers");
        louder.defaultInput = device("input", "other-microphone");
        louder.effects.output.activePreset = "Previous Output";
        louder.effects.output.presets.push("Previous Output");
        louder.effects.input.activePreset = "Previous Input";
        louder.effects.input.presets.push("Previous Input");
        louder.output.volume = 1;
        louder.input.volume = 0.9;
        const plan = AudioSceneModel.applyPlan(captured, louder);
        verify(plan.accepted);
        compare(plan.steps.map(step => step.kind).join(","), "device,device,preset,preset,ceiling,ceiling");
        compare(plan.steps[0].rollback.stableKey, "output-device:other-speakers");
        compare(plan.steps[2].rollback.preset, "Previous Output");
        compare(plan.steps[4].value, 0.8);

        const quieter = context();
        quieter.output.volume = 0.2;
        quieter.input.volume = 0.2;
        const quietPlan = AudioSceneModel.applyPlan(captured, quieter);
        verify(quietPlan.accepted);
        compare(quietPlan.steps.map(step => step.kind).join(","), "ceiling,ceiling");
    }

    function test_applyPlanFailsBeforeMutationWhenReferenceIsMissing() {
        const scene = AudioSceneModel.capture("Studio", context(), [], "1").scene;
        const missing = context();
        missing.nodes = [device("input", "microphone")];
        missing.effects.input.presets = [];
        const plan = AudioSceneModel.applyPlan(scene, missing);

        verify(!plan.accepted);
        compare(plan.code, "scene-unavailable");
        compare(plan.steps, []);
        compare(plan.issues.length, 2);
    }

    function test_applyPlanRejectsIrreversibleChangesAndSkipsCurrentReferences() {
        const scene = AudioSceneModel.capture("Studio", context(), [], "1").scene;
        const current = context();
        const plan = AudioSceneModel.applyPlan(scene, current);
        verify(plan.accepted);
        compare(plan.steps.map(step => step.kind).join(","), "ceiling,ceiling");

        const noDeviceRollback = context();
        noDeviceRollback.defaultOutput = null;
        noDeviceRollback.nodes.push(device("output", "other"));
        const changedDevice = Object.assign({}, scene, {
            outputDeviceKey: "output-device:other"
        });
        const devicePlan = AudioSceneModel.applyPlan(changedDevice, noDeviceRollback);
        verify(!devicePlan.accepted);
        verify(devicePlan.issues[0].includes("restored safely"));

        const noPresetRollback = context();
        noPresetRollback.effects.output.activePreset = "";
        const changedPreset = Object.assign({}, scene, {
            outputPreset: "Other"
        });
        noPresetRollback.effects.output.presets.push("Other");
        const presetPlan = AudioSceneModel.applyPlan(changedPreset, noPresetRollback);
        verify(!presetPlan.accepted);
        verify(presetPlan.issues[0].includes("restored safely"));
    }

    function test_removeIsExplicitAndStable() {
        const first = AudioSceneModel.capture("First", context(), [], "1");
        const second = AudioSceneModel.capture("Second", context(), first.scenes, "2");
        const removed = AudioSceneModel.remove(second.scenes, first.scene.id);
        verify(removed.accepted);
        compare(removed.scenes.map(scene => scene.name), ["Second"]);
        compare(AudioSceneModel.remove(removed.scenes, "missing").code, "scene-unavailable");
    }
}
