import QtQuick
import QtTest
import "../../services/audio/AudioStatusModel.js" as AudioStatusModel

TestCase {
    name: "AudioStatusModel"

    function counts(outputs, inputs, playback, recording) {
        return {
            outputDevices: outputs,
            inputDevices: inputs,
            playbackStreams: playback,
            recordingStreams: recording
        };
    }

    function test_unloadedIsNotReportedAsBackendFailure() {
        const status = AudioStatusModel.derive(false, false, counts(0, 0, 0, 0), {}, {});

        compare(status.state, "unloaded");
        compare(status.ready, null);
        compare(status.backend.pipewire, "unloaded");
        compare(status.errors.length, 0);
    }

    function test_masterHealthIsIndependentFromOptionalInventory() {
        const status = AudioStatusModel.deriveMaster(true, {
            available: true,
            ready: true
        }, {
            available: true,
            ready: true
        });

        compare(status.state, "ready");
        verify(status.ready);
        compare(status.backend.pipewire, "ready");
        compare(status.backend.sessionManager, "observed");
        compare(status.warnings.length, 0);
    }

    function test_masterHealthReportsHonestEmptyAndDegradedStates() {
        const empty = AudioStatusModel.deriveMaster(true, {}, {});
        const degraded = AudioStatusModel.deriveMaster(true, {
            available: true,
            ready: false
        }, {});

        compare(empty.state, "empty");
        verify(empty.emptyStates.noOutput);
        verify(empty.emptyStates.noInput);
        compare(degraded.state, "degraded");
        compare(degraded.warnings[0].code, "default-output-not-ready");
    }

    function test_readyGraphExposesEmptyStreamStates() {
        const status = AudioStatusModel.derive(true, true, counts(1, 1, 0, 0), {
            output: {
                id: 1
            },
            input: {
                id: 2
            }
        }, {});

        compare(status.state, "ready");
        compare(status.backend.sessionManager, "observed");
        verify(status.emptyStates.noPlaybackStreams);
        verify(status.emptyStates.noRecordingStreams);
        verify(!status.emptyStates.noOutputDevices);
        verify(!status.emptyStates.noInputDevices);
    }

    function test_missingDevicesAreTruthfulEmptyState() {
        const status = AudioStatusModel.derive(true, true, counts(0, 0, 0, 0), {}, {});

        compare(status.state, "empty");
        compare(status.backend.sessionManager, "unconfirmed");
        verify(status.emptyStates.noOutputDevices);
        verify(status.emptyStates.noInputDevices);
        compare(status.warnings.length, 0);
    }

    function test_missingPublishedDefaultIsDegradedNotInventedFailure() {
        const status = AudioStatusModel.derive(true, true, counts(1, 1, 0, 0), {}, {});

        compare(status.state, "degraded");
        compare(status.backend.sessionManager, "unconfirmed");
        compare(status.warnings.length, 2);
        compare(status.errors.length, 0);
    }

    function test_boundedWatchdogProducesStructuredUnavailableState() {
        const status = AudioStatusModel.derive(true, false, counts(0, 0, 0, 0), {}, {
            code: "pipewire-unavailable",
            message: "Connection timed out"
        });

        compare(status.state, "unavailable");
        compare(status.backend.pipewire, "unavailable");
        compare(status.errors[0].code, "pipewire-unavailable");
    }
}
