import QtQuick
import QtTest
import "../../services/audio/AudioPrivacyPresentationModel.js" as AudioPrivacyPresentationModel

TestCase {
    name: "AudioPrivacyPresentationModel"

    function state(clients, paths, microphoneActive) {
        return {
            microphoneActive: microphoneActive,
            clients: clients,
            paths: paths
        };
    }

    function client(key, name, identified) {
        return {
            key: key,
            displayName: name,
            identified: identified
        };
    }

    function path(key, microphone) {
        return {
            clientKey: key,
            microphone: microphone
        };
    }

    function test_idleStateHasNoPresentation() {
        const result = AudioPrivacyPresentationModel.presentation(state([], [], false));

        verify(!result.active);
        compare(result.clientCount, 0);
        compare(result.title, "");
        compare(result.detail, "");
    }

    function test_singleMicrophoneClientShowsApplication() {
        const result = AudioPrivacyPresentationModel.presentation(state([client("application-id:meeting", "Meeting", true)], [path("application-id:meeting", true)], true));

        verify(result.active);
        compare(result.title, "Meeting");
        compare(result.detail, "Using microphone");
    }

    function test_monitorClientIsExcludedFromMicrophonePresentation() {
        const result = AudioPrivacyPresentationModel.presentation(state([client("binary:recorder", "Recorder", true), client("application-id:meeting", "Meeting", true)], [path("binary:recorder", false), path("application-id:meeting", true)], true));

        compare(result.clientCount, 1);
        compare(result.title, "Meeting");
    }

    function test_multipleClientsRemainCompact() {
        const result = AudioPrivacyPresentationModel.presentation(state([client("binary:recorder", "Recorder", true), client("application-id:meeting", "Meeting", true)], [path("binary:recorder", true), path("application-id:meeting", true)], true));

        compare(result.clientCount, 2);
        compare(result.title, "Meeting +1");
        compare(result.detail, "2 apps using microphone");
    }

    function test_missingClientIsTruthful() {
        const result = AudioPrivacyPresentationModel.presentation(state([], [path("unknown:node:9", true)], true));

        compare(result.title, "Unknown application");
        compare(result.detail, "Using microphone");
    }
}
