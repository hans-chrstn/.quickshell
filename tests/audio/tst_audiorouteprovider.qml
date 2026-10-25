import QtQuick
import QtTest
import "../../services/audio"

TestCase {
    id: testCase

    name: "AudioRouteProvider"

    property var records: []
    property var applications: ({
            playing: [],
            recording: []
        })
    property var links: []
    property int defaultOutputId: 30
    property int graphRevision: 1

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

    function output(id, serial, name) {
        return {
            id: id,
            objectSerial: serial,
            sessionId: "pipewire-serial:" + serial,
            stableKey: "output-device:" + name,
            role: "output-device",
            specialization: "physical",
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

    function metadataResult(streamId, output) {
        return {
            streamId: streamId,
            stdout: output
        };
    }

    QtObject {
        id: executor

        property bool busy: false
        property bool acceptsRuns: true
        property int activeToken: 0
        property var batches: []

        signal completed(int token, var results)
        signal failed(int token, int commandIndex, string code, string message, var results)

        function run(commands, token) {
            if (busy || !acceptsRuns)
                return false;
            busy = true;
            activeToken = token;
            batches = batches.concat([commands]);
            return true;
        }

        function succeed(results) {
            const token = activeToken;
            busy = false;
            completed(token, results || []);
        }

        function reject(code, message) {
            const token = activeToken;
            busy = false;
            failed(token, 0, code || "command-failed", message || "failed", []);
        }
    }

    AudioRouteProvider {
        id: provider

        records: testCase.records
        applications: testCase.applications
        links: testCase.links
        defaultOutputId: testCase.defaultOutputId
        graphRevision: testCase.graphRevision
        commandExecutor: executor
    }

    SignalSpy {
        id: resultSpy

        target: provider
        signalName: "resultOccurred"
    }

    function init() {
        provider.confirmationTimer.stop();
        provider.busy = false;
        provider.sequence = 0;
        provider.operation = null;
        provider.lastResult = null;
        provider.requestCount = 0;
        provider.commandCount = 0;
        provider.confirmedCount = 0;
        provider.rollbackCount = 0;
        provider.failedCount = 0;
        provider.timeoutCount = 0;
        provider.abortReason = null;
        resultSpy.clear();
        executor.busy = false;
        executor.acceptsRuns = true;
        executor.activeToken = 0;
        executor.batches = [];
        const streams = [stream(20, 200), stream(21, 201)];
        records = streams.concat([output(30, 300, "Speakers"), output(31, 301, "Headphones")]);
        applications = application(streams);
        links = [
            {
                sourceId: 20,
                targetId: 30
            },
            {
                sourceId: 21,
                targetId: 30
            }
        ];
        defaultOutputId = 30;
        graphRevision += 1;
    }

    function test_targetRouteConfirmsMetadataAndEveryNativeLink() {
        const result = provider.request("playback-stream:application-id:player", "output-device:Headphones");

        verify(result.accepted);
        compare(provider.operation.phase, "reading-originals");
        compare(executor.batches[0].length, 2);
        executor.succeed([metadataResult(20, "Found metadata"), metadataResult(21, "Found metadata")]);
        compare(provider.operation.phase, "mutating");
        compare(executor.batches[1].length, 4);
        executor.succeed([]);
        compare(provider.operation.phase, "verifying-metadata");
        const pinned = "update: id:20 key:'target.object' value:'301' type:'Spa:Id'";
        executor.succeed([metadataResult(20, pinned), metadataResult(21, pinned)]);
        compare(provider.operation.phase, "awaiting-links");
        verify(provider.busy);

        links = [
            {
                sourceId: 20,
                targetId: 31
            },
            {
                sourceId: 21,
                targetId: 31
            }
        ];
        graphRevision += 1;

        verify(!provider.busy);
        compare(provider.lastResult.code, "confirmed");
        compare(provider.lastResult.origin, "manual");
        compare(provider.lastResult.applicationKey, "application-id:player");
        verify(provider.lastResult.metadataConfirmed);
        verify(provider.lastResult.linksConfirmed);
        compare(provider.confirmedCount, 1);
        compare(resultSpy.count, 1);
    }

    function test_failureRestoresExactOriginalMetadata() {
        const result = provider.request("playback-stream:application-id:player", "output-device:Headphones");
        verify(result.accepted);
        const original20 = "update: id:20 key:'target.object' value:'300' type:'Spa:Id'\nupdate: id:20 key:'target.node' value:'30' type:'Spa:Id'";
        const original21 = "update: id:21 key:'target.object' value:'300' type:'Spa:Id'";
        executor.succeed([metadataResult(20, original20), metadataResult(21, original21)]);
        compare(provider.operation.phase, "mutating");
        executor.reject("command-failed", "mutation failed");

        compare(provider.operation.phase, "rolling-back");
        const rollback = executor.batches[2];
        compare(rollback[0].command.join("|"), "pw-metadata|-n|default|20|target.object|300|Spa:Id");
        compare(rollback[1].command.join("|"), "pw-metadata|-n|default|20|target.node|30|Spa:Id");
        compare(rollback[2].command.join("|"), "pw-metadata|-n|default|21|target.object|300|Spa:Id");
        compare(rollback[3].command.join("|"), "pw-metadata|-n|default|-d|21|target.node");
        executor.succeed([]);
        compare(provider.operation.phase, "verifying-rollback");
        executor.succeed([metadataResult(20, original20), metadataResult(21, original21)]);

        verify(!provider.busy);
        compare(provider.lastResult.code, "command-failed");
        verify(provider.lastResult.rollbackConfirmed);
        compare(provider.rollbackCount, 1);
    }

    function test_streamChurnBeforeMutationFailsClosedWithoutWriting() {
        const result = provider.request("playback-stream:application-id:player", "output-device:Headphones");
        verify(result.accepted);
        applications = application([stream(22, 202)]);
        graphRevision += 1;
        executor.succeed([metadataResult(20, "Found metadata"), metadataResult(21, "Found metadata")]);

        verify(!provider.busy);
        compare(provider.lastResult.code, "stream-set-changed");
        compare(executor.batches.length, 1);
    }

    function test_targetRemovalBeforeMutationFailsWithoutWriting() {
        const result = provider.request("playback-stream:application-id:player", "output-device:Headphones");
        verify(result.accepted);
        records = records.filter(record => record.stableKey !== "output-device:Headphones");
        graphRevision += 1;
        executor.succeed([metadataResult(20, "Found metadata"), metadataResult(21, "Found metadata")]);

        verify(!provider.busy);
        compare(provider.lastResult.code, "target-changed");
        compare(executor.batches.length, 1);
    }

    function test_targetIdentityReplacementDuringMutationRollsBack() {
        const result = provider.request("playback-stream:application-id:player", "output-device:Headphones");
        verify(result.accepted);
        executor.succeed([metadataResult(20, "Found metadata"), metadataResult(21, "Found metadata")]);
        compare(provider.operation.phase, "mutating");

        records = records.filter(record => record.stableKey !== "output-device:Headphones").concat([output(31, 302, "Headphones")]);
        graphRevision += 1;
        executor.succeed([]);
        compare(provider.operation.phase, "rolling-back");
        executor.succeed([]);
        compare(provider.operation.phase, "verifying-rollback");
        executor.succeed([metadataResult(20, "Found metadata"), metadataResult(21, "Found metadata")]);

        verify(!provider.busy);
        compare(provider.lastResult.code, "target-changed");
        verify(provider.lastResult.rollbackConfirmed);
    }

    function test_followDefaultTracksAChangedEffectiveDefault() {
        const result = provider.request("playback-stream:application-id:player", "");
        verify(result.accepted);
        executor.succeed([metadataResult(20, "Found metadata"), metadataResult(21, "Found metadata")]);
        executor.succeed([]);

        defaultOutputId = 31;
        graphRevision += 1;
        executor.succeed([metadataResult(20, "Found metadata"), metadataResult(21, "Found metadata")]);
        compare(provider.operation.phase, "awaiting-links");

        links = [
            {
                sourceId: 20,
                targetId: 31
            },
            {
                sourceId: 21,
                targetId: 31
            }
        ];
        graphRevision += 1;

        verify(!provider.busy);
        compare(provider.lastResult.code, "confirmed");
        verify(provider.lastResult.linksConfirmed);
    }

    function test_followDefaultDisappearanceDuringMutationRollsBackImmediately() {
        const result = provider.request("playback-stream:application-id:player", "");
        verify(result.accepted);
        executor.succeed([metadataResult(20, "Found metadata"), metadataResult(21, "Found metadata")]);
        compare(provider.operation.phase, "mutating");

        defaultOutputId = 0;
        graphRevision += 1;
        executor.succeed([]);
        compare(provider.operation.phase, "rolling-back");
        executor.succeed([]);
        executor.succeed([metadataResult(20, "Found metadata"), metadataResult(21, "Found metadata")]);

        verify(!provider.busy);
        compare(provider.lastResult.code, "default-unavailable");
        verify(provider.lastResult.rollbackConfirmed);
    }

    function test_followDefaultClearsModernAndLegacyPins() {
        const result = provider.request("playback-stream:application-id:player", "");
        verify(result.accepted);
        executor.succeed([metadataResult(20, "Found metadata"), metadataResult(21, "Found metadata")]);

        const mutation = executor.batches[1];
        compare(mutation[0].command.join("|"), "pw-metadata|-n|default|-d|20|target.object");
        compare(mutation[1].command.join("|"), "pw-metadata|-n|default|-d|20|target.node");
        compare(mutation[2].command.join("|"), "pw-metadata|-n|default|-d|21|target.object");
        compare(mutation[3].command.join("|"), "pw-metadata|-n|default|-d|21|target.node");
    }

    function test_unavailableRollbackExecutorTerminatesWithoutRecursion() {
        const result = provider.request("playback-stream:application-id:player", "output-device:Headphones");
        verify(result.accepted);
        executor.succeed([metadataResult(20, "Found metadata"), metadataResult(21, "Found metadata")]);
        executor.acceptsRuns = false;
        executor.reject("command-failed", "mutation failed");

        verify(!provider.busy);
        compare(provider.lastResult.code, "rollback-failed");
        verify(!provider.lastResult.rollbackConfirmed);
        compare(provider.rollbackCount, 1);
        compare(executor.batches.length, 2);
    }
}
