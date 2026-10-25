import QtQuick
import QtTest
import "../../services/audio/AudioRouteModel.js" as AudioRouteModel

TestCase {
    name: "AudioRouteModel"

    function stream(id, serial) {
        return {
            id: id,
            sessionId: "pipewire-serial:" + serial,
            stableKey: "pipewire-serial:" + serial,
            role: "playback-stream",
            specialization: "application",
            displayName: "Player",
            ready: true
        };
    }

    function output(id, serial, name, role, specialization) {
        return {
            id: id,
            sessionId: "pipewire-serial:" + serial,
            stableKey: (role || "output-device") + ":" + name,
            role: role || "output-device",
            specialization: specialization || "physical",
            displayName: name,
            ready: true
        };
    }

    function application(streams) {
        return {
            playing: [
                {
                    key: "playback-stream:application-id:player",
                    applicationKey: "application-id:player",
                    direction: "output",
                    active: true,
                    ready: true,
                    streamCount: streams.length,
                    streams: streams
                }
            ],
            recording: []
        };
    }

    function test_targetsIncludePhysicalAndEffectOutputsOnly() {
        const physical = output(10, 100, "Speakers");
        physical.isDefault = true;
        const effect = output(11, 101, "Easy Effects", "specialized-node", "virtual-output");
        const input = output(12, 102, "Microphone", "input-device", "physical");
        const unavailable = output(13, 103, "Gone");
        unavailable.ready = false;

        const targets = AudioRouteModel.outputTargets([effect, input, unavailable, physical]);

        compare(targets.length, 2);
        compare(targets[0].displayName, "Speakers");
        verify(targets[0].physical);
        verify(targets[0].isDefault);
        compare(targets[1].displayName, "Easy Effects");
        verify(targets[1].effect);
    }

    function test_routeRowsAndObservedSelectionUseDynamicTargets() {
        const speakers = output(30, 300, "Speakers");
        speakers.isDefault = true;
        const effect = output(31, 301, "Easy Effects", "specialized-node", "virtual-output");
        const targets = AudioRouteModel.outputTargets([effect, speakers]);
        const rows = AudioRouteModel.routeRows(targets, {
            id: 30,
            name: "Speakers"
        });

        compare(rows.length, 2);
        compare(rows[0].key, "default");
        compare(rows[0].displayName, "Speakers");
        compare(rows[0].detail, "System default");
        verify(rows[0].available);
        compare(rows[1].key, "specialized-node:Easy Effects");
        verify(rows[1].available);
        verify(rows[1].effect);
        compare(AudioRouteModel.observedRouteKey({
            routeTargetIds: [30]
        }, rows, 30), "default");
        compare(AudioRouteModel.observedRouteKey({
            routeTargetIds: [31]
        }, rows, 30), "specialized-node:Easy Effects");
        compare(AudioRouteModel.observedRouteKey({
            routeTargetIds: [30, 31]
        }, rows, 30), "");
    }

    function test_routeSelectionIsStableAndBounded() {
        const rows = [
            {
                key: "default"
            },
            {
                key: "speakers"
            },
            {
                key: "effects"
            }
        ];

        compare(AudioRouteModel.routeSelectionKey(rows, "", "retain"), "default");
        compare(AudioRouteModel.routeSelectionKey(rows, "default", "next"), "speakers");
        compare(AudioRouteModel.routeSelectionKey(rows, "speakers", "next"), "effects");
        compare(AudioRouteModel.routeSelectionKey(rows, "effects", "next"), "effects");
        compare(AudioRouteModel.routeSelectionKey(rows, "default", "previous"), "default");
        compare(AudioRouteModel.routeSelectionKey(rows, "missing", "previous"), "effects");
        compare(AudioRouteModel.routeSelectionKey(rows, "speakers", "first"), "default");
        compare(AudioRouteModel.routeSelectionKey(rows, "speakers", "last"), "effects");
    }

    function test_unavailableDefaultIsTruthfulAndSkippedByNavigation() {
        const rows = AudioRouteModel.routeRows([output(42, 420, "Speakers")], {});

        compare(rows.length, 2);
        compare(rows[0].displayName, "System Output");
        verify(!rows[0].available);
        verify(rows[1].available);
        compare(AudioRouteModel.routeSelectionKey(rows, "", "first"), "output-device:Speakers");
        compare(AudioRouteModel.routeSelectionKey(rows, "output-device:Speakers", "previous"), "output-device:Speakers");
    }

    function test_probePlanUsesNativeNodeAndStableSerial() {
        const plan = AudioRouteModel.probePlan([stream(20, 200), output(30, 300, "Headphones")], 20, 30);

        verify(plan.accepted);
        compare(plan.streamId, 20);
        compare(plan.streamSessionId, "pipewire-serial:200");
        compare(plan.targetId, 30);
        compare(plan.targetSerial, 300);
        compare(plan.targetStableKey, "output-device:Headphones");
    }

    function test_probePlanRejectsStaleIdsAndInvalidTargets() {
        const records = [stream(20, 200), output(30, 300, "Headphones")];

        compare(AudioRouteModel.probePlan(records, 21, 30).code, "stream-unavailable");
        compare(AudioRouteModel.probePlan(records, 20, 31).code, "target-unavailable");
    }

    function test_routeObservationDetectsDefaultSplitAndMissingLinks() {
        const records = [stream(20, 200), stream(21, 201), output(30, 300, "Speakers"), output(31, 301, "Headphones")];
        const defaultRoute = AudioRouteModel.routeObservation([20], records, [
            {
                sourceId: 20,
                targetId: 30
            }
        ], 30);
        const splitRoute = AudioRouteModel.routeObservation([20, 21], records, [
            {
                sourceId: 20,
                targetId: 30
            },
            {
                sourceId: 21,
                targetId: 31
            }
        ], 30);
        const missingRoute = AudioRouteModel.routeObservation([20], records, [], 30);

        verify(defaultRoute.onDefaultOutput);
        verify(!defaultRoute.split);
        verify(splitRoute.split);
        compare(splitRoute.routeCount, 2);
        verify(!missingRoute.linked);
    }

    function test_metadataPinDetectionCoversModernAndLegacyKeys() {
        verify(AudioRouteModel.metadataPinned("update: id:20 key:'target.object' value:'300'"));
        verify(AudioRouteModel.metadataPinned("update: id:20 key:'target.node' value:'30'"));
        verify(!AudioRouteModel.metadataPinned("Found \"default\" metadata 45"));
    }

    function test_applicationPlanSupportsStableTargetAndFollowDefault() {
        const streams = [stream(20, 200), stream(21, 201)];
        const records = streams.concat([output(30, 300, "Speakers"), output(31, 301, "Headphones")]);
        const targeted = AudioRouteModel.applicationRoutePlan(application(streams), records, "playback-stream:application-id:player", "output-device:Headphones", 30);
        const following = AudioRouteModel.applicationRoutePlan(application(streams), records, "playback-stream:application-id:player", "", 30);

        verify(targeted.accepted);
        compare(targeted.streamIds.join(","), "20,21");
        compare(targeted.targetId, 31);
        compare(targeted.targetSerial, 301);
        verify(!targeted.followDefault);
        verify(following.accepted);
        verify(following.followDefault);
        compare(following.defaultOutputId, 30);
    }

    function test_applicationPlanAndContinuityFailClosed() {
        const streams = [stream(20, 200)];
        const records = streams.concat([output(30, 300, "Speakers")]);
        const plan = AudioRouteModel.applicationRoutePlan(application(streams), records, "playback-stream:application-id:player", "", 30);
        const changedStreams = [stream(22, 202)];

        compare(AudioRouteModel.applicationRoutePlan(application(streams), records, "missing", "", 30).code, "application-ended");
        compare(AudioRouteModel.applicationRoutePlan(application(streams), records, "playback-stream:application-id:player", "", 0).code, "default-unavailable");
        compare(AudioRouteModel.applicationRoutePlan(application(streams), records, "playback-stream:application-id:player", "missing", 30).code, "target-unavailable");
        compare(AudioRouteModel.routeContinuity(plan, application(changedStreams), records, 30).code, "stream-set-changed");
    }

    function test_routesMatchRequiresEveryStreamOnOneExpectedTarget() {
        const streams = [stream(20, 200), stream(21, 201)];
        const records = streams.concat([output(30, 300, "Speakers"), output(31, 301, "Headphones")]);
        const plan = AudioRouteModel.applicationRoutePlan(application(streams), records, "playback-stream:application-id:player", "output-device:Headphones", 30);

        verify(AudioRouteModel.routesMatch(plan, records, [
            {
                sourceId: 20,
                targetId: 31
            },
            {
                sourceId: 21,
                targetId: 31
            }
        ], 30));
        verify(!AudioRouteModel.routesMatch(plan, records, [
            {
                sourceId: 20,
                targetId: 31
            },
            {
                sourceId: 21,
                targetId: 30
            }
        ], 30));
    }

    function test_metadataParsingMatchingAndExactRollbackCommands() {
        const outputText = "Found metadata\nupdate: id:20 key:'target.object' value:'301' type:'Spa:Id'\nupdate: id:20 key:'target.node' value:'31' type:'Spa:Id'";
        const original = AudioRouteModel.metadataState(outputText);
        const streams = [stream(20, 200)];
        const records = streams.concat([output(30, 300, "Speakers"), output(31, 301, "Headphones")]);
        const plan = AudioRouteModel.applicationRoutePlan(application(streams), records, "playback-stream:application-id:player", "output-device:Headphones", 30);

        compare(original.targetObject.value, "301");
        compare(original.targetNode.value, "31");
        verify(!AudioRouteModel.metadataMatches(original, plan));
        verify(AudioRouteModel.metadataMatches(AudioRouteModel.metadataState("update: id:20 key:'target.object' value:'301' type:'Spa:Id'"), plan));
        verify(AudioRouteModel.metadataEqual(original, AudioRouteModel.metadataState(outputText)));

        const mutation = AudioRouteModel.mutationCommands(plan);
        compare(mutation.length, 2);
        compare(mutation[0].command.join(" "), "pw-metadata -n default 20 target.object 301 Spa:Id");
        compare(mutation[1].command.join(" "), "pw-metadata -n default -d 20 target.node");

        const rollback = AudioRouteModel.rollbackCommands([20], {
            "20": original
        });
        compare(rollback[0].command.join(" "), "pw-metadata -n default 20 target.object 301 Spa:Id");
        compare(rollback[1].command.join(" "), "pw-metadata -n default 20 target.node 31 Spa:Id");
    }

    function test_followDefaultCommandsClearBothKeysAndMatchEmptyMetadata() {
        const streams = [stream(20, 200)];
        const records = streams.concat([output(30, 300, "Speakers")]);
        const plan = AudioRouteModel.applicationRoutePlan(application(streams), records, "playback-stream:application-id:player", "", 30);
        const mutation = AudioRouteModel.mutationCommands(plan);

        verify(AudioRouteModel.metadataMatches(AudioRouteModel.metadataState("Found metadata"), plan));
        compare(mutation[0].command.join(" "), "pw-metadata -n default -d 20 target.object");
        compare(mutation[1].command.join(" "), "pw-metadata -n default -d 20 target.node");
    }
}
