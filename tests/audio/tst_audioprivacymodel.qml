import QtQuick
import QtTest
import "../../services/audio/AudioPrivacyModel.js" as AudioPrivacyModel

TestCase {
    name: "AudioPrivacyModel"

    function source(id, role, specialization, name) {
        return {
            id: id,
            stableKey: role + ":" + name,
            role: role,
            specialization: specialization,
            displayName: name,
            ready: true
        };
    }

    function recorder(id, applicationKey, name) {
        return {
            id: id,
            sessionId: "pipewire-serial:" + id,
            stableKey: "pipewire-serial:" + id,
            role: "recording-stream",
            specialization: "application",
            applicationKey: applicationKey || "",
            applicationName: name || "",
            displayName: name || "Private media title",
            iconName: "microphone-app",
            ready: true
        };
    }

    function link(sourceId, targetId) {
        return {
            sourceId: sourceId,
            targetId: targetId
        };
    }

    function test_physicalMicrophoneRequiresLiveLinkAndAttributesApplication() {
        const microphone = source(10, "input-device", "physical", "Studio Mic");
        const meeting = recorder(20, "application-id:meeting", "Meeting");
        const idle = AudioPrivacyModel.snapshot([microphone, meeting], [], true);
        const active = AudioPrivacyModel.snapshot([microphone, meeting], [link(10, 20)], true);

        verify(!idle.captureActive);
        verify(active.captureActive);
        verify(active.microphoneActive);
        compare(active.clientCount, 1);
        compare(active.clients[0].displayName, "Meeting");
        verify(active.clients[0].identified);
        compare(active.sources[0].kind, "physical-microphone");
    }

    function test_monitorCaptureDoesNotBecomeMicrophoneWarning() {
        const monitor = source(11, "specialized-node", "monitor-source", "Output Monitor");
        const recorderNode = recorder(21, "binary:recorder", "Recorder");
        const result = AudioPrivacyModel.snapshot([monitor, recorderNode], [link(11, 21)], true);

        verify(result.captureActive);
        verify(result.monitorCaptureActive);
        verify(!result.microphoneActive);
        verify(!result.unknownCaptureActive);
        compare(result.paths[0].kind, "monitor-capture");
    }

    function test_virtualInputCountsAsMicrophoneWithoutPretendingPhysical() {
        const effectInput = source(12, "specialized-node", "virtual-input", "Easy Effects Source");
        const browser = recorder(22, "application-id:browser", "Browser");
        const result = AudioPrivacyModel.snapshot([effectInput, browser], [link(12, 22)], true);

        verify(result.microphoneActive);
        compare(result.sources[0].kind, "virtual-microphone");
        verify(result.sources[0].microphone);
    }

    function test_unknownSourceAndClientRemainTruthfulAndPrivate() {
        const unknownClient = recorder(23, "", "Private media title");
        const result = AudioPrivacyModel.snapshot([unknownClient], [link(99, 23)], true);

        verify(result.captureActive);
        verify(result.unknownCaptureActive);
        verify(!result.microphoneActive);
        compare(result.clients[0].displayName, "Unknown application");
        verify(!result.clients[0].identified);
        verify(JSON.stringify(result).indexOf("Private media title") < 0);
    }

    function test_playbackAndWrongDirectionLinksCannotTriggerCapture() {
        const microphone = source(10, "input-device", "physical", "Studio Mic");
        const playback = {
            id: 30,
            role: "playback-stream",
            ready: true
        };
        const recording = recorder(20, "binary:recorder", "Recorder");
        const result = AudioPrivacyModel.snapshot([microphone, playback, recording], [link(30, 10), link(20, 10), link(10, 30)], true);

        verify(!result.captureActive);
        compare(result.pathCount, 0);
    }

    function test_multipleClientsAndDuplicateLinksAreBounded() {
        const microphone = source(10, "input-device", "physical", "Studio Mic");
        const first = recorder(20, "application-id:meeting", "Meeting");
        const second = recorder(21, "binary:recorder", "Recorder");
        const result = AudioPrivacyModel.snapshot([microphone, first, second], [link(10, 20), link(10, 20), link(10, 21)], true);

        compare(result.pathCount, 2);
        compare(result.clientCount, 2);
        compare(result.sourceCount, 1);
        verify(result.microphoneActive);
    }

    function test_linkedSourceDiscoveryUsesReadyRecordingTargetsOnly() {
        const recording = recorder(20, "application-id:meeting", "Meeting");
        const unavailable = recorder(21, "binary:recorder", "Recorder");
        unavailable.ready = false;
        const sourceIds = AudioPrivacyModel.linkedSourceIds([recording, unavailable], [link(10, 20), link(11, 21), link(12, 30), link(10, 20)]);

        compare(sourceIds.length, 1);
        compare(sourceIds[0], 10);
    }

    function test_malformedInputFailsClosedWithoutInventingCapture() {
        const result = AudioPrivacyModel.snapshot(null, [
            {
                sourceId: "bad",
                targetId: -1
            }
        ], false);

        verify(!result.backendReady);
        verify(!result.captureActive);
        compare(result.clients.length, 0);
        compare(result.sources.length, 0);
    }
}
