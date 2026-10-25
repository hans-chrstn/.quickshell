import QtQuick
import QtTest
import "../../services/audio/AudioHotplugModel.js" as AudioHotplugModel

TestCase {
    name: "AudioHotplugModel"

    function device(key, role, name, ready, current, nodeId) {
        return {
            id: nodeId || 1,
            stableKey: key,
            role: role + "-device",
            displayName: name,
            ready: ready,
            isDefault: current
        };
    }

    function current(device) {
        return device ? {
            id: device.id,
            stableKey: device.stableKey,
            name: device.displayName,
            ready: device.ready
        } : null;
    }

    function initialized(role, records, currentDevice) {
        return AudioHotplugModel.reconcile(AudioHotplugModel.emptyState(role), records, current(currentDevice));
    }

    function test_initialDiscoveryAndManualChangesRemainQuiet() {
        const speakers = device("output:speakers", "output", "Speakers", true, true, 10);
        const headphones = device("output:headphones", "output", "Headphones", true, false, 20);
        const baseline = initialized("output", [speakers, headphones], speakers);
        compare(baseline.event.kind, "");

        const manual = AudioHotplugModel.reconcile(baseline, [Object.assign({}, speakers, {
                isDefault: false
            }), Object.assign({}, headphones, {
                isDefault: true
            })], current(headphones));
        compare(manual.event.kind, "");
        compare(manual.defaultStableKey, headphones.stableKey);
    }

    function test_currentRemovalReportsFallbackWithoutChoosingIt() {
        const speakers = device("output:speakers", "output", "Speakers", true, true, 10);
        const headphones = device("output:headphones", "output", "Headphones", true, false, 20);
        const baseline = initialized("output", [speakers, headphones], speakers);
        const fallback = Object.assign({}, headphones, {
            isDefault: true
        });
        const changed = AudioHotplugModel.reconcile(baseline, [fallback], current(fallback));

        compare(changed.event.kind, "fallback");
        compare(changed.event.fromStableKey, speakers.stableKey);
        compare(changed.event.toStableKey, headphones.stableKey);
        compare(changed.displacedStableKey, speakers.stableKey);
        verify(changed.event.message.includes("using Headphones"));
    }

    function test_noFallbackAndLateFallbackAreDistinct() {
        const microphone = device("input:mic", "input", "USB Mic", true, true, 30);
        const fallback = device("input:webcam", "input", "Webcam Mic", true, false, 40);
        const baseline = initialized("input", [microphone, fallback], microphone);
        const missing = AudioHotplugModel.reconcile(baseline, [fallback], null);
        compare(missing.event.kind, "disconnected");
        verify(missing.event.message.includes("no input available"));

        const activeFallback = Object.assign({}, fallback, {
            isDefault: true
        });
        const settled = AudioHotplugModel.reconcile(missing, [activeFallback], current(activeFallback));
        compare(settled.event.kind, "fallback");
        compare(settled.displacedStableKey, microphone.stableKey);
    }

    function test_reconnectReportsPipeWireDecisionAndAcceptsNewNodeId() {
        const speakers = device("output:speakers", "output", "Speakers", true, true, 10);
        const headphones = device("output:headphones", "output", "Headphones", true, false, 20);
        const baseline = initialized("output", [speakers, headphones], speakers);
        const fallback = Object.assign({}, headphones, {
            isDefault: true
        });
        const displaced = AudioHotplugModel.reconcile(baseline, [fallback], current(fallback));

        const reconnected = Object.assign({}, speakers, {
            id: 99,
            isDefault: false
        });
        const stayed = AudioHotplugModel.reconcile(displaced, [fallback, reconnected], current(fallback));
        compare(stayed.event.kind, "available-again");
        compare(stayed.defaultStableKey, headphones.stableKey);
        compare(stayed.displacedStableKey, "");

        const displacedAgain = AudioHotplugModel.reconcile(baseline, [fallback], current(fallback));
        const restored = Object.assign({}, reconnected, {
            isDefault: true
        });
        const returned = AudioHotplugModel.reconcile(displacedAgain, [headphones, restored], current(restored));
        compare(returned.event.kind, "restored");
        compare(returned.event.fromStableKey, speakers.stableKey);
        compare(returned.defaultStableKey, speakers.stableKey);
    }

    function test_nonDefaultHotplugAndVirtualDefaultDoNotInventFallbacks() {
        const speakers = device("output:speakers", "output", "Speakers", true, true, 10);
        const headphones = device("output:headphones", "output", "Headphones", true, false, 20);
        const baseline = initialized("output", [speakers, headphones], speakers);
        const removedSecondary = AudioHotplugModel.reconcile(baseline, [speakers], current(speakers));
        compare(removedSecondary.event.kind, "");

        const virtualBaseline = initialized("output", [headphones], {
            id: 50,
            stableKey: "specialized-node:easyeffects",
            displayName: "Easy Effects Sink",
            ready: true
        });
        const unchanged = AudioHotplugModel.reconcile(virtualBaseline, [headphones], {
            id: 50,
            stableKey: "specialized-node:easyeffects",
            name: "Easy Effects Sink",
            ready: true
        });
        compare(unchanged.event.kind, "");
    }
}
