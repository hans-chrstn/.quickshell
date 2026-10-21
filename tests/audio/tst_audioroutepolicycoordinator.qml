import QtQuick
import QtTest
import "../../services/audio"

TestCase {
    id: testCase

    name: "AudioRoutePolicyCoordinator"
    property var policies: ({})
    property var applications: ({
            playing: []
        })
    property var targets: []
    property int defaultOutputId: 30
    property int graphRevision: 0

    function application(routeTargetIds, sessionId) {
        return {
            playing: [
                {
                    key: "playback-stream:application-id:player",
                    applicationKey: "application-id:player",
                    direction: "output",
                    active: true,
                    ready: true,
                    streamSessionIds: [sessionId || "pipewire-serial:1"],
                    routeTargetIds: routeTargetIds
                }
            ]
        };
    }

    function target(id, serial) {
        return {
            id: id,
            objectSerial: serial,
            stableKey: "output-device:headphones"
        };
    }

    QtObject {
        id: provider

        property bool busy: false
        property var requests: []

        function request(groupKey, targetStableKey, origin) {
            requests = requests.concat([
                {
                    groupKey: groupKey,
                    targetStableKey: targetStableKey,
                    origin: origin
                }
            ]);
            busy = true;
            return {
                accepted: true,
                code: "accepted"
            };
        }
    }

    AudioRoutePolicyCoordinator {
        id: coordinator

        policies: testCase.policies
        applications: testCase.applications
        targets: testCase.targets
        defaultOutputId: testCase.defaultOutputId
        graphRevision: testCase.graphRevision
        provider: provider
    }

    function init() {
        policies = ({});
        applications = ({
                playing: []
            });
        targets = [];
        defaultOutputId = 30;
        graphRevision += 1;
        provider.busy = false;
        provider.requests = [];
        coordinator.attemptedSignatures = ({});
        coordinator.requestCount = 0;
        coordinator.acceptedCount = 0;
        coordinator.rejectedCount = 0;
        coordinator.lastDecision = null;
        wait(1);
    }

    function test_appliesRememberedTargetOnceAndStopsWhenCurrent() {
        policies = {
            "application-id:player": {
                targetStableKey: "output-device:headphones"
            }
        };
        applications = application([30]);
        targets = [target(31, 301)];
        graphRevision += 1;

        tryCompare(provider, "busy", true);
        compare(provider.requests.length, 1);
        compare(provider.requests[0].targetStableKey, "output-device:headphones");
        compare(provider.requests[0].origin, "policy-apply");

        applications = application([31]);
        graphRevision += 1;
        provider.busy = false;
        wait(1);
        compare(provider.requests.length, 1);
    }

    function test_missingTargetFallsBackOnlyWhenUnlinked() {
        policies = {
            "application-id:player": {
                targetStableKey: "output-device:headphones"
            }
        };
        applications = application([]);
        graphRevision += 1;

        tryCompare(provider, "busy", true);
        compare(provider.requests.length, 1);
        compare(provider.requests[0].targetStableKey, "");
        compare(provider.requests[0].origin, "policy-fallback");
    }

    function test_missingTargetPreservesAnExistingRoute() {
        policies = {
            "application-id:player": {
                targetStableKey: "output-device:headphones"
            }
        };
        applications = application([30]);
        graphRevision += 1;

        wait(1);
        compare(provider.requests.length, 0);
        compare(coordinator.plans[0].state, "target-unavailable");
    }

    function test_retriesOnlyAfterRelevantIdentityChanges() {
        policies = {
            "application-id:player": {
                targetStableKey: "output-device:headphones"
            }
        };
        applications = application([30]);
        targets = [target(31, 301)];
        graphRevision += 1;
        tryCompare(provider, "busy", true);
        compare(provider.requests.length, 1);

        provider.busy = false;
        graphRevision += 1;
        wait(1);
        compare(provider.requests.length, 1);

        applications = application([30], "pipewire-serial:2");
        graphRevision += 1;
        tryCompare(provider, "busy", true);
        compare(provider.requests.length, 2);
    }
}
