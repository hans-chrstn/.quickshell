import QtQuick
import QtTest
import "../../services/audio/AudioDeviceModel.js" as AudioDeviceModel

TestCase {
    name: "AudioDeviceModel"

    function device(key, role, name, ready, current, preferred) {
        return {
            stableKey: key,
            role: role,
            displayName: name,
            ready: ready,
            isDefault: current,
            isPreferredDefault: preferred,
            capabilities: {
                preferredDefaultWrite: true
            }
        };
    }

    function test_filtersExactPhysicalRolesAndKeepsDeterministicOrder() {
        const nodes = [device("input:b", "input-device", "Beta mic", true, false, false), device("virtual", "specialized-node", "Effect sink", true, false, false), device("output:z", "output-device", "Zeta speakers", true, true, true), device("output:a", "output-device", "Alpha headphones", true, false, false), device("output:u", "output-device", "Unavailable", false, false, false)];

        const outputs = AudioDeviceModel.devicesForRole(nodes, "output-device");
        const inputs = AudioDeviceModel.devicesForRole(nodes, "input-device");

        compare(outputs.map(item => item.stableKey).join(","), "output:a,output:z,output:u");
        compare(inputs.length, 1);
        compare(inputs[0].stableKey, "input:b");
        compare(nodes.length, 5);
    }

    function test_defaultChangeMovesStateWithoutReorderingRows() {
        const first = [device("output:a", "output-device", "Alpha headphones", true, true, true), device("output:z", "output-device", "Zeta speakers", true, false, false)];
        const changed = [device("output:a", "output-device", "Alpha headphones", true, false, false), device("output:z", "output-device", "Zeta speakers", true, true, true)];

        compare(AudioDeviceModel.devicesForRole(first, "output-device").map(item => item.stableKey).join(","), "output:a,output:z");
        compare(AudioDeviceModel.devicesForRole(changed, "output-device").map(item => item.stableKey).join(","), "output:a,output:z");
    }

    function test_rejectsUnknownRole() {
        compare(AudioDeviceModel.devicesForRole([], "playback-stream").length, 0);
    }

    function test_statusLabelsRemainTruthful() {
        compare(AudioDeviceModel.statusLabel(device("a", "output-device", "A", false, true, true)), "Unavailable");
        compare(AudioDeviceModel.statusLabel(device("b", "output-device", "B", true, true, true)), "Default");
        compare(AudioDeviceModel.statusLabel(device("c", "output-device", "C", true, false, true)), "Preferred");
        compare(AudioDeviceModel.statusLabel(device("d", "output-device", "D", true, false, false)), "Available");
    }

    function test_cycleUsesStableOrderAndWraps() {
        const alpha = device("output:a", "output-device", "Alpha", true, true, true);
        const beta = device("output:b", "output-device", "Beta", true, false, false);
        const gamma = device("output:g", "output-device", "Gamma", true, false, false);
        const nodes = [gamma, alpha, beta];

        compare(AudioDeviceModel.cyclePlan(nodes, "output-device", alpha.stableKey, 1).target.stableKey, beta.stableKey);
        compare(AudioDeviceModel.cyclePlan(nodes, "output-device", gamma.stableKey, 1).target.stableKey, alpha.stableKey);
        compare(AudioDeviceModel.cyclePlan(nodes, "output-device", alpha.stableKey, -1).target.stableKey, gamma.stableKey);
    }

    function test_cycleSkipsUnavailableAndReadOnlyDevices() {
        const alpha = device("output:a", "output-device", "Alpha", true, true, true);
        const beta = device("output:b", "output-device", "Beta", false, false, false);
        const gamma = device("output:g", "output-device", "Gamma", true, false, false);
        gamma.capabilities.preferredDefaultWrite = false;

        compare(AudioDeviceModel.cycleCandidates([alpha, beta, gamma], "output-device").length, 1);
        compare(AudioDeviceModel.cyclePlan([alpha, beta, gamma], "output-device", alpha.stableKey, 1).code, "insufficient-devices");
        compare(AudioDeviceModel.cyclePlan([alpha], "playback-stream", alpha.stableKey, 1).code, "invalid-role");
    }
}
