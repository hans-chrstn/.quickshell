import QtQuick
import QtTest
import "../../services/audio/AudioDefaultModel.js" as AudioDefaultModel

TestCase {
    name: "AudioDefaultModel"

    function device(key, role, ready, current, preferred, writable) {
        return {
            id: key === "speakers" ? 10 : 20,
            stableKey: key,
            role: role,
            ready: ready,
            isDefault: current,
            isPreferredDefault: preferred,
            capabilities: {
                preferredDefaultWrite: writable
            }
        };
    }

    function test_requestValidationFailsClosed() {
        const speakers = device("speakers", "output-device", true, true, true, true);
        compare(AudioDefaultModel.requestPlan("other", "speakers", [speakers], true).code, "invalid-role");
        compare(AudioDefaultModel.requestPlan("output", "speakers", [speakers], false).code, "backend-unavailable");
        compare(AudioDefaultModel.requestPlan("output", "", [speakers], true).code, "invalid-device");
        compare(AudioDefaultModel.requestPlan("output", "missing", [speakers], true).code, "device-unavailable");
        compare(AudioDefaultModel.requestPlan("input", "speakers", [speakers], true).code, "role-mismatch");

        const unavailable = device("headphones", "output-device", false, false, false, true);
        compare(AudioDefaultModel.requestPlan("output", "headphones", [unavailable], true).code, "device-not-ready");
        const readOnly = device("headphones", "output-device", true, false, false, false);
        compare(AudioDefaultModel.requestPlan("output", "headphones", [readOnly], true).code, "control-unavailable");
    }

    function test_requestDistinguishesCurrentFromNewTarget() {
        const speakers = device("speakers", "output-device", true, true, true, true);
        const headphones = device("headphones", "output-device", true, false, false, true);
        const current = AudioDefaultModel.requestPlan("output", "speakers", [speakers, headphones], true);
        verify(current.accepted);
        compare(current.code, "unchanged");
        const next = AudioDefaultModel.requestPlan("output", "headphones", [speakers, headphones], true);
        verify(next.accepted);
        compare(next.code, "accepted");
        compare(next.target.stableKey, "headphones");
    }

    function test_reconciliationSeparatesPreferenceFromEffectiveDefault() {
        const speakers = device("speakers", "output-device", true, true, true, true);
        const headphones = device("headphones", "output-device", true, false, false, true);
        const requested = AudioDefaultModel.requestedState("output", headphones, 4, [speakers, headphones]);
        compare(requested.phase, "requested");
        compare(requested.actualStableKey, "speakers");

        const oldPreferredSpeakers = Object.assign({}, speakers, {
            isPreferredDefault: false
        });
        const preferredHeadphones = Object.assign({}, headphones, {
            isPreferredDefault: true
        });
        const preferred = AudioDefaultModel.reconciledState(requested, [oldPreferredSpeakers, preferredHeadphones]);
        compare(preferred.phase, "preferred");
        compare(preferred.code, "effective-pending");
        compare(preferred.actualStableKey, "speakers");
        compare(preferred.preferredStableKey, "headphones");

        const oldSpeakers = Object.assign({}, speakers, {
            isDefault: false,
            isPreferredDefault: false
        });
        const currentHeadphones = Object.assign({}, headphones, {
            isDefault: true,
            isPreferredDefault: true
        });
        const confirmed = AudioDefaultModel.reconciledState(preferred, [oldSpeakers, currentHeadphones]);
        compare(confirmed.phase, "confirmed");
        compare(confirmed.code, "confirmed");
        compare(confirmed.actualStableKey, "headphones");
    }

    function test_disappearanceSupersessionAndTimeoutAreExplicit() {
        const speakers = device("speakers", "output-device", true, true, true, true);
        const headphones = device("headphones", "output-device", true, false, false, true);
        const requested = AudioDefaultModel.requestedState("output", headphones, 2, [speakers, headphones]);

        const missing = AudioDefaultModel.reconciledState(requested, [speakers]);
        compare(missing.phase, "failed");
        compare(missing.code, "device-unavailable");

        const timeout = AudioDefaultModel.timedOutState(requested, [speakers, headphones]);
        compare(timeout.phase, "failed");
        compare(timeout.code, "confirmation-timeout");

        const preferred = Object.assign({}, requested, {
            phase: "preferred"
        });
        const superseded = AudioDefaultModel.reconciledState(preferred, [speakers, headphones]);
        compare(superseded.phase, "superseded");
        compare(superseded.code, "preference-superseded");
    }
}
