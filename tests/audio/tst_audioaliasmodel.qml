import QtQuick
import QtTest
import "../../services/audio/AudioAliasModel.js" as AudioAliasModel

TestCase {
    name: "AudioAliasModel"

    function device(key, role, name) {
        return {
            stableKey: key,
            role: role,
            displayName: name
        };
    }

    function test_normalizesOnlyBoundedPhysicalDeviceAliases() {
        const aliases = AudioAliasModel.normalizedAliases({
            "output-device:speakers": "  Desk   Speakers  ",
            "input-device:mic": "Studio\nMic",
            "pipewire-node:42": "Transient",
            "output-device:empty": "   "
        });

        compare(aliases["output-device:speakers"], "Desk Speakers");
        compare(aliases["input-device:mic"], "Studio Mic");
        verify(aliases["pipewire-node:42"] === undefined);
        verify(aliases["output-device:empty"] === undefined);
    }

    function test_setAndClearUseStableIdentity() {
        const speakers = device("output-device:speakers", "output-device", "Long hardware name");
        const setPlan = AudioAliasModel.requestPlan([speakers], ({}), speakers.stableKey, "Desk Speakers");
        verify(setPlan.accepted);
        compare(setPlan.code, "alias-set");
        compare(setPlan.aliases[speakers.stableKey], "Desk Speakers");
        compare(AudioAliasModel.displayName(speakers, setPlan.aliases), "Desk Speakers");

        const clearPlan = AudioAliasModel.requestPlan([speakers], setPlan.aliases, speakers.stableKey, "");
        verify(clearPlan.accepted);
        compare(clearPlan.code, "alias-cleared");
        compare(AudioAliasModel.displayName(speakers, clearPlan.aliases), "Long hardware name");
    }

    function test_rejectsTransientMissingAndOversizedTargets() {
        const speakers = device("output-device:speakers", "output-device", "Speakers");
        compare(AudioAliasModel.requestPlan([speakers], ({}), "pipewire-node:42", "Desk").code, "invalid-device");
        compare(AudioAliasModel.requestPlan([], ({}), speakers.stableKey, "Desk").code, "device-unavailable");
        compare(AudioAliasModel.requestPlan([speakers], ({}), speakers.stableKey, "x".repeat(65)).code, "alias-too-long");
    }
}
