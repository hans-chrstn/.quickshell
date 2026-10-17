import QtQuick
import QtTest
import "../../services/audio/AudioApplicationControlModel.js" as AudioApplicationControlModel

TestCase {
    name: "AudioApplicationControlModel"

    function group(overrides) {
        return Object.assign({
            key: "playback-stream:application-id:player",
            direction: "output",
            active: true,
            ready: true,
            streamCount: 2,
            streamNodeIds: [10, 11],
            volume: 0.5,
            muted: false,
            mixedVolume: false,
            mixedMute: false,
            capabilities: {
                volumeWrite: true,
                muteWrite: true
            }
        }, overrides || ({}));
    }

    function applications(values) {
        return {
            playing: values || [group()],
            recording: []
        };
    }

    function test_targetUsesCurrentStableGroupAndEveryStream() {
        const target = AudioApplicationControlModel.controlTarget(applications(), "playback-stream:application-id:player", "volume");

        verify(target.accepted);
        compare(target.role, "output");
        compare(target.nodeIds.length, 2);
        compare(target.nodeIds[0], 10);
        compare(target.nodeIds[1], 11);
    }

    function test_recordingMapsToInputControlRole() {
        const recording = group({
            key: "recording-stream:application-id:meeting",
            direction: "input",
            streamCount: 1,
            streamNodeIds: [21]
        });
        const target = AudioApplicationControlModel.controlTarget({
            playing: [],
            recording: [recording]
        }, recording.key, "mute");

        verify(target.accepted);
        compare(target.role, "input");
        compare(target.nodeIds[0], 21);
    }

    function test_endedIncompleteAndReadOnlyGroupsFailClosed() {
        const ended = AudioApplicationControlModel.controlTarget(applications([]), "playback-stream:application-id:player", "volume");
        const incomplete = AudioApplicationControlModel.controlTarget(applications([group({
                streamCount: 2,
                streamNodeIds: [10]
            })]), "playback-stream:application-id:player", "volume");
        const readOnly = AudioApplicationControlModel.controlTarget(applications([group({
                capabilities: {
                    volumeWrite: true,
                    muteWrite: false
                }
            })]), "playback-stream:application-id:player", "mute");

        compare(ended.code, "application-ended");
        compare(incomplete.code, "stream-set-invalid");
        compare(readOnly.code, "control-unavailable");
    }

    function test_confirmationRejectsMixedOrPartialState() {
        const pending = {
            active: true,
            volume: 0.7,
            muted: false
        };

        verify(AudioApplicationControlModel.targetMatches(group({
            volume: 0.7
        }), pending, 0.02));
        verify(!AudioApplicationControlModel.targetMatches(group({
            volume: 0.7,
            mixedVolume: true
        }), pending, 0.02));
        verify(!AudioApplicationControlModel.targetMatches(group({
            volume: 0.7,
            mixedMute: true
        }), pending, 0.02));
    }
}
