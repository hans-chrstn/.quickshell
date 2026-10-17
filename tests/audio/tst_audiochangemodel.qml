import QtQuick
import QtTest
import "../../services/audio/AudioChangeModel.js" as AudioChangeModel

TestCase {
    name: "AudioChangeModel"

    function record(role, id, volume, muted) {
        return {
            role: role,
            available: true,
            id: id,
            key: role + ":device-" + id,
            name: "Device " + id,
            ready: true,
            volume: volume,
            muted: muted,
            capabilities: {
                volumeWrite: true,
                muteWrite: true
            }
        };
    }

    function test_normalizationFailsClosed() {
        const missing = AudioChangeModel.normalizedRecord("output", null);
        const malformed = AudioChangeModel.normalizedRecord("input", {
            available: true,
            id: 4,
            volume: "not-a-number",
            muted: "false"
        });

        verify(!missing.available);
        compare(missing.id, -1);
        compare(missing.volume, null);
        verify(malformed.available);
        compare(malformed.volume, null);
        compare(malformed.muted, null);
    }

    function test_deviceIdentityUsesStableKeyAndCurrentNodeId() {
        const current = record("output", 10, 0.5, false);
        const same = Object.assign({}, current, {
            volume: 0.8
        });
        const replacement = Object.assign({}, current, {
            id: 11
        });

        verify(AudioChangeModel.sameDevice(current, same));
        verify(!AudioChangeModel.sameDevice(current, replacement));
    }

    function test_hardwareQuantizationMatchesPendingTarget() {
        const current = record("output", 10, 0.600006, false);
        const target = Object.assign({}, current, {
            active: true,
            volume: 0.6,
            muted: false
        });

        verify(AudioChangeModel.targetMatches(current, target));
    }

    function test_effectiveRecordUsesOptimisticStateOnlyForSameDevice() {
        const current = record("input", 20, 0.4, false);
        const matching = Object.assign({}, current, {
            active: true,
            phase: "queued",
            volume: 0.7,
            muted: true
        });
        const stale = Object.assign({}, matching, {
            id: 21
        });

        const optimistic = AudioChangeModel.effectiveRecord("input", current, matching);
        const unchanged = AudioChangeModel.effectiveRecord("input", current, stale);
        compare(optimistic.volume, 0.7);
        verify(optimistic.muted);
        verify(optimistic.optimistic);
        compare(unchanged.volume, 0.4);
        verify(!unchanged.muted);
    }

    function test_semanticEventsExposeOnlyActualStateChanges() {
        const before = record("output", 10, 0.4, false);
        const after = Object.assign({}, before, {
            volume: 0.5,
            muted: true
        });
        const event = AudioChangeModel.semanticEvent(3, "external", "state", before, after);

        compare(event.sequence, 3);
        compare(event.source, "external");
        compare(event.role, "output");
        compare(event.changedFields.length, 2);
        compare(event.changedFields[0], "volume");
        compare(event.changedFields[1], "muted");
    }
}
