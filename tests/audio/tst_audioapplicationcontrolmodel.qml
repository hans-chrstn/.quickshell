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
            streams: [
                {
                    id: 10,
                    sessionId: "pipewire-serial:10",
                    ready: true,
                    volume: 0.5,
                    muted: false,
                    capabilities: {
                        volumeWrite: true,
                        muteWrite: true
                    }
                },
                {
                    id: 11,
                    sessionId: "pipewire-serial:11",
                    ready: true,
                    volume: 0.5,
                    muted: false,
                    capabilities: {
                        volumeWrite: true,
                        muteWrite: true
                    }
                }
            ],
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
            streamNodeIds: [21],
            streams: [
                {
                    id: 21,
                    sessionId: "pipewire-serial:21",
                    ready: true,
                    volume: 0.5,
                    muted: false,
                    capabilities: {
                        volumeWrite: true,
                        muteWrite: true
                    }
                }
            ]
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

    function test_streamTargetUsesStableSessionIdentity() {
        const target = AudioApplicationControlModel.streamControlTarget(applications(), "playback-stream:application-id:player", "pipewire-serial:11", "volume");

        verify(target.accepted);
        compare(target.role, "output");
        compare(target.sessionId, "pipewire-serial:11");
        compare(target.nodeIds.length, 1);
        compare(target.nodeIds[0], 11);
    }

    function test_streamTargetFailsClosedWhenEndedOrReadOnly() {
        const ended = AudioApplicationControlModel.streamControlTarget(applications(), "playback-stream:application-id:player", "pipewire-serial:99", "volume");
        const readOnlyGroup = group();
        readOnlyGroup.streams[0] = Object.assign({}, readOnlyGroup.streams[0], {
            capabilities: {
                volumeWrite: true,
                muteWrite: false
            }
        });
        const readOnly = AudioApplicationControlModel.streamControlTarget(applications([readOnlyGroup]), readOnlyGroup.key, "pipewire-serial:10", "mute");

        compare(ended.code, "stream-ended");
        compare(readOnly.code, "control-unavailable");
    }

    function test_streamConfirmationUsesOnlySelectedStream() {
        const current = group();
        const pending = {
            active: true,
            sessionId: "pipewire-serial:11",
            volume: 0.7,
            muted: true
        };

        current.streams[1] = Object.assign({}, current.streams[1], {
            volume: 0.7,
            muted: true
        });
        verify(AudioApplicationControlModel.streamTargetMatches(current, pending, 0.02));
        current.streams[0] = Object.assign({}, current.streams[0], {
            volume: 0.1,
            muted: false
        });
        verify(AudioApplicationControlModel.streamTargetMatches(current, pending, 0.02));
        pending.sessionId = "pipewire-serial:99";
        verify(!AudioApplicationControlModel.streamTargetMatches(current, pending, 0.02));
    }

    function test_pendingGroupRejectsChangedStreamSet() {
        const initial = group();
        const target = AudioApplicationControlModel.controlTarget(applications([initial]), initial.key, "volume");
        const pending = Object.assign({}, target, {
            active: true,
            scope: "group"
        });
        const replacement = group({
            streamNodeIds: [10, 12],
            streams: [initial.streams[0], Object.assign({}, initial.streams[1], {
                    id: 12,
                    sessionId: "pipewire-serial:12"
                })]
        });

        verify(AudioApplicationControlModel.targetContinuity(initial, pending).accepted);
        compare(AudioApplicationControlModel.targetContinuity(replacement, pending).code, "stream-set-changed");
    }

    function test_pendingStreamRejectsEndReplacementAndCapabilityLoss() {
        const initial = group();
        const target = AudioApplicationControlModel.streamControlTarget(applications([initial]), initial.key, "pipewire-serial:10", "volume");
        const pending = Object.assign({}, target, {
            active: true,
            scope: "stream"
        });
        const ended = group({
            streamCount: 1,
            streamNodeIds: [11],
            streams: [initial.streams[1]]
        });
        const replaced = group();
        replaced.streams[0] = Object.assign({}, replaced.streams[0], {
            id: 12
        });
        const readOnly = group();
        readOnly.streams[0] = Object.assign({}, readOnly.streams[0], {
            capabilities: {
                volumeWrite: false,
                muteWrite: false
            }
        });

        verify(AudioApplicationControlModel.targetContinuity(initial, pending).accepted);
        compare(AudioApplicationControlModel.targetContinuity(ended, pending).code, "stream-ended");
        compare(AudioApplicationControlModel.targetContinuity(replaced, pending).code, "stream-changed");
        compare(AudioApplicationControlModel.targetContinuity(readOnly, pending).code, "control-unavailable");
    }
}
