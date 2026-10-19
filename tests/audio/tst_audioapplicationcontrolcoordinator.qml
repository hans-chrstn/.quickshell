import QtQuick
import QtTest
import "../../services/audio"

TestCase {
    id: testCase

    name: "AudioApplicationControlCoordinator"

    function group(volume, muted) {
        return {
            key: "playback-stream:application-id:player",
            direction: "output",
            active: true,
            ready: true,
            streamCount: 2,
            streamNodeIds: [10, 11],
            volume: volume,
            muted: muted,
            mixedVolume: false,
            mixedMute: false,
            streams: [
                {
                    id: 10,
                    sessionId: "pipewire-serial:10",
                    ready: true,
                    volume: volume,
                    muted: muted,
                    capabilities: {
                        volumeWrite: true,
                        muteWrite: true
                    }
                },
                {
                    id: 11,
                    sessionId: "pipewire-serial:11",
                    ready: true,
                    volume: volume,
                    muted: muted,
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
        };
    }

    function applicationSet(values) {
        return {
            playing: values,
            recording: []
        };
    }

    QtObject {
        id: provider

        property int revision: 1
        property int applyCount: 0
        property int streamApplyCount: 0
        property bool deferConfirmation: false
        property var applications: testCase.applicationSet([testCase.group(0.5, false)])

        function applyApplicationState(request) {
            const current = applications.playing.find(group => group.key === request.groupKey);
            if (!current) {
                return {
                    accepted: false,
                    code: "application-ended",
                    message: "The application ended."
                };
            }
            applyCount += 1;
            if (deferConfirmation) {
                return {
                    accepted: true,
                    code: "accepted",
                    message: ""
                };
            }
            applications = testCase.applicationSet([Object.assign({}, current, {
                    volume: request.volume,
                    muted: request.muted,
                    mixedVolume: false,
                    mixedMute: false
                })]);
            revision += 1;
            return {
                accepted: true,
                code: "accepted",
                message: ""
            };
        }

        function applyApplicationStreamState(request) {
            const current = applications.playing.find(group => group.key === request.groupKey);
            const streamIndex = current?.streams.findIndex(stream => stream.sessionId === request.sessionId) ?? -1;
            if (!current || streamIndex < 0) {
                return {
                    accepted: false,
                    code: "stream-ended",
                    message: "The stream ended."
                };
            }
            const streams = current.streams.slice();
            streams[streamIndex] = Object.assign({}, streams[streamIndex], {
                volume: request.volume,
                muted: request.muted
            });
            streamApplyCount += 1;
            if (deferConfirmation) {
                return {
                    accepted: true,
                    code: "accepted",
                    message: ""
                };
            }
            applications = testCase.applicationSet([Object.assign({}, current, {
                    streams: streams
                })]);
            revision += 1;
            return {
                accepted: true,
                code: "accepted",
                message: ""
            };
        }
    }

    AudioApplicationControlCoordinator {
        id: coordinator

        provider: provider
        policy: ({
                step: 0.05,
                outputCeiling: 1,
                inputCeiling: 1,
                muteAtZero: true,
                restoreOnUnmute: true
            })
    }

    function init() {
        coordinator.flushTimer.stop();
        coordinator.confirmationTimer.stop();
        coordinator.pendingByTarget = ({});
        coordinator.sequence = 0;
        coordinator.requestCount = 0;
        coordinator.coalescedRequestCount = 0;
        coordinator.nativeApplyCount = 0;
        coordinator.confirmedCount = 0;
        coordinator.cancelledCount = 0;
        coordinator.timeoutCount = 0;
        coordinator.lastResult = null;
        provider.applyCount = 0;
        provider.streamApplyCount = 0;
        provider.deferConfirmation = false;
        provider.applications = applicationSet([group(0.5, false)]);
        provider.revision += 1;
    }

    function test_dragRequestsCoalesceIntoOneNativeGroupWrite() {
        coordinator.setVolume("playback-stream:application-id:player", 0.6);
        coordinator.setVolume("playback-stream:application-id:player", 0.7);
        coordinator.setVolume("playback-stream:application-id:player", 0.8);

        compare(coordinator.effectiveGroup(provider.applications.playing[0]).volume, 0.8);
        compare(coordinator.requestCount, 3);
        compare(coordinator.coalescedRequestCount, 2);
        coordinator.flushTimer.stop();
        coordinator.flush();

        compare(provider.applyCount, 1);
        compare(provider.applications.playing[0].volume, 0.8);
        compare(coordinator.nativeApplyCount, 1);
        compare(coordinator.confirmedCount, 1);
        verify(!coordinator.busy);
    }

    function test_mutePublishesOptimisticallyAndConfirms() {
        const result = coordinator.setMuted("playback-stream:application-id:player", true);

        verify(result.accepted);
        verify(coordinator.effectiveGroup(provider.applications.playing[0]).muted);
        coordinator.flushTimer.stop();
        coordinator.flush();

        verify(provider.applications.playing[0].muted);
        compare(coordinator.confirmedCount, 1);
        verify(!coordinator.busy);
    }

    function test_applicationExitBeforeFlushCancelsWithoutWrite() {
        coordinator.setVolume("playback-stream:application-id:player", 0.3);
        provider.applications = applicationSet([]);
        provider.revision += 1;
        coordinator.flushTimer.stop();
        coordinator.flush();

        compare(provider.applyCount, 0);
        compare(coordinator.cancelledCount, 1);
        compare(coordinator.lastResult.code, "application-ended");
        verify(!coordinator.busy);
    }

    function test_streamDragCoalescesAndOnlyChangesSelectedStream() {
        const key = "playback-stream:application-id:player";
        coordinator.setStreamVolume(key, "pipewire-serial:10", 0.6);
        coordinator.setStreamVolume(key, "pipewire-serial:10", 0.7);
        coordinator.setStreamVolume(key, "pipewire-serial:10", 0.8);

        compare(coordinator.effectiveStream(key, provider.applications.playing[0].streams[0]).volume, 0.8);
        compare(coordinator.effectiveStream(key, provider.applications.playing[0].streams[1]).volume, 0.5);
        coordinator.flushTimer.stop();
        coordinator.flush();

        compare(provider.streamApplyCount, 1);
        compare(provider.applications.playing[0].streams[0].volume, 0.8);
        compare(provider.applications.playing[0].streams[1].volume, 0.5);
        compare(coordinator.confirmedCount, 1);
        verify(!coordinator.busy);
    }

    function test_groupRequestSupersedesQueuedStreamRequest() {
        const key = "playback-stream:application-id:player";
        coordinator.setStreamVolume(key, "pipewire-serial:10", 0.7);
        coordinator.setVolume(key, 0.8);
        coordinator.flushTimer.stop();
        coordinator.flush();

        compare(provider.streamApplyCount, 0);
        compare(provider.applyCount, 1);
        compare(coordinator.cancelledCount, 1);
        compare(provider.applications.playing[0].volume, 0.8);
    }

    function test_awaitingStreamCancelsImmediatelyWhenStreamEnds() {
        const key = "playback-stream:application-id:player";
        provider.deferConfirmation = true;
        coordinator.setStreamVolume(key, "pipewire-serial:10", 0.8);
        coordinator.flushTimer.stop();
        coordinator.flush();
        verify(coordinator.busy);

        const current = provider.applications.playing[0];
        provider.applications = applicationSet([Object.assign({}, current, {
                streamCount: 1,
                streamNodeIds: [11],
                streams: [current.streams[1]]
            })]);
        provider.revision += 1;

        verify(!coordinator.busy);
        compare(coordinator.lastResult.code, "stream-ended");
        compare(coordinator.timeoutCount, 0);
    }

    function test_awaitingGroupCancelsImmediatelyWhenStreamSetChanges() {
        const key = "playback-stream:application-id:player";
        provider.deferConfirmation = true;
        coordinator.setVolume(key, 0.8);
        coordinator.flushTimer.stop();
        coordinator.flush();
        verify(coordinator.busy);

        const current = provider.applications.playing[0];
        provider.applications = applicationSet([Object.assign({}, current, {
                streamNodeIds: [10, 12],
                streams: [current.streams[0], Object.assign({}, current.streams[1], {
                        id: 12,
                        sessionId: "pipewire-serial:12"
                    })]
            })]);
        provider.revision += 1;

        verify(!coordinator.busy);
        compare(coordinator.lastResult.code, "stream-set-changed");
        compare(coordinator.timeoutCount, 0);
    }
}
