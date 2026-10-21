import QtQuick
import QtTest
import "../../services/audio/AudioPrivacyMuteModel.js" as AudioPrivacyMuteModel

TestCase {
    name: "AudioPrivacyMuteModel"

    function privacy(active) {
        return {
            microphoneActive: active
        };
    }

    function input(available, ready, writable, muted) {
        return {
            available: available,
            ready: ready,
            name: "Studio Input",
            muted: muted,
            capabilities: {
                muteWrite: writable
            }
        };
    }

    function test_stateNamesTruthfulNarrowScope() {
        const result = AudioPrivacyMuteModel.controlState(privacy(true), input(true, true, true, false), {
            active: true
        });

        compare(result.scope, "default-input");
        compare(result.scopeLabel, "Default input only");
        compare(result.detail, "Other microphone paths are not blocked");
        compare(result.targetName, "Studio Input");
        verify(result.canControl);
        verify(result.busy);
        verify(!result.muted);
    }

    function test_inactiveCaptureRejectsMutation() {
        const result = AudioPrivacyMuteModel.requestPlan(privacy(false), input(true, true, true, false), true);

        verify(!result.accepted);
        compare(result.code, "no-active-microphone");
        compare(result.scope, "default-input");
    }

    function test_unavailableDefaultRejectsWithoutClaimingGlobalControl() {
        const result = AudioPrivacyMuteModel.requestPlan(privacy(true), input(true, true, false, false), true);

        verify(!result.accepted);
        compare(result.code, "default-input-unavailable");
        compare(result.targetName, "Studio Input");
    }

    function test_validRequestDelegatesOnlyDefaultInputIntent() {
        const result = AudioPrivacyMuteModel.requestPlan(privacy(true), input(true, true, true, false), true);

        verify(result.accepted);
        compare(result.code, "ready");
        compare(result.scope, "default-input");
        compare(result.targetName, "Studio Input");
        verify(result.muted);
    }

    function test_invalidBooleanFailsClosed() {
        const result = AudioPrivacyMuteModel.requestPlan(privacy(true), input(true, true, true, false), "true");

        verify(!result.accepted);
        compare(result.code, "invalid-request");
    }
}
