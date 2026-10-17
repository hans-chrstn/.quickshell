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
        coordinator.pendingByGroup = ({});
        coordinator.sequence = 0;
        coordinator.requestCount = 0;
        coordinator.coalescedRequestCount = 0;
        coordinator.nativeApplyCount = 0;
        coordinator.confirmedCount = 0;
        coordinator.cancelledCount = 0;
        coordinator.timeoutCount = 0;
        coordinator.lastResult = null;
        provider.applyCount = 0;
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
}
