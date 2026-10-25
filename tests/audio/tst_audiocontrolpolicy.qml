import QtQuick
import QtTest
import "../../services/audio/AudioControlPolicy.js" as AudioControlPolicy

TestCase {
    name: "AudioControlPolicy"

    function test_outputAndInputRolesAreExplicit() {
        compare(AudioControlPolicy.normalizedRole("OUTPUT"), "output");
        compare(AudioControlPolicy.normalizedRole(" input "), "input");
        compare(AudioControlPolicy.normalizedRole("speaker"), "");
    }

    function test_volumeIsBoundedToRoleCeiling() {
        const ordinary = AudioControlPolicy.volumeRequest("output", 4, 1);
        const reduced = AudioControlPolicy.volumeRequest("input", -1, 0.8);

        verify(ordinary.accepted);
        compare(ordinary.value, 1);
        verify(reduced.accepted);
        compare(reduced.value, 0);
    }

    function test_invalidVolumeFailsClosed() {
        const invalidRole = AudioControlPolicy.volumeRequest("speaker", 0.5, 1);
        const invalidValue = AudioControlPolicy.volumeRequest("output", Number.NaN, 1);

        verify(!invalidRole.accepted);
        compare(invalidRole.code, "invalid-role");
        verify(!invalidValue.accepted);
        compare(invalidValue.code, "invalid-volume");
    }

    function test_muteRequiresBooleanAndKnownRole() {
        const accepted = AudioControlPolicy.muteRequest("input", true);
        const rejected = AudioControlPolicy.muteRequest("output", 1);

        verify(accepted.accepted);
        verify(accepted.value);
        verify(!rejected.accepted);
        compare(rejected.code, "invalid-mute");
    }

    function test_policyDefaultsSafeAndBoundsOptInAmplification() {
        const defaults = AudioControlPolicy.normalizedPolicy({});
        const bounded = AudioControlPolicy.normalizedPolicy({
            step: 8,
            outputCeiling: 4,
            inputCeiling: 0.2,
            muteAtZero: false,
            restoreOnUnmute: false
        });

        compare(defaults.step, 0.05);
        compare(defaults.outputCeiling, 1);
        compare(defaults.inputCeiling, 1);
        verify(defaults.muteAtZero);
        verify(defaults.restoreOnUnmute);
        compare(bounded.step, 0.2);
        compare(bounded.outputCeiling, 1.5);
        compare(bounded.inputCeiling, 1);
        verify(!bounded.muteAtZero);
        verify(!bounded.restoreOnUnmute);
    }

    function test_zeroVolumeAndPositiveVolumeDriveMutePolicy() {
        const zero = AudioControlPolicy.volumePlan("output", 0, 0.4, {});
        const positive = AudioControlPolicy.volumePlan("input", 0.25, 0, {});
        const zeroWithoutMute = AudioControlPolicy.volumePlan("output", 0, 0.4, {
            muteAtZero: false
        });

        verify(zero.accepted);
        verify(zero.muted);
        compare(zero.rememberedVolume, 0.4);
        verify(!positive.muted);
        compare(positive.volume, 0.25);
        verify(!zeroWithoutMute.muted);
    }

    function test_unmuteRestoresOnlyProvidedMatchingMemory() {
        const restored = AudioControlPolicy.mutePlan("output", 0, true, false, 0.62, {});
        const fallback = AudioControlPolicy.mutePlan("input", 0, true, false, 0, {});
        const disabled = AudioControlPolicy.mutePlan("output", 0, true, false, 0.62, {
            restoreOnUnmute: false
        });

        compare(restored.volume, 0.62);
        compare(fallback.volume, 0.05);
        compare(disabled.volume, 0);
        verify(!restored.muted);
    }

    function test_adjustmentUsesStepCeilingAndZeroMute() {
        const raised = AudioControlPolicy.adjustmentPlan("output", 0.95, false, 2, 0, {
            step: 0.05,
            outputCeiling: 1
        });
        const lowered = AudioControlPolicy.adjustmentPlan("input", 0.03, false, -1, 0.03, {
            step: 0.05
        });
        const invalid = AudioControlPolicy.adjustmentPlan("output", 0.5, false, 0, 0.5, {});

        compare(raised.volume, 1);
        verify(raised.clamped);
        compare(lowered.volume, 0);
        verify(lowered.muted);
        verify(!invalid.accepted);
        compare(invalid.code, "invalid-adjustment");
    }
}
