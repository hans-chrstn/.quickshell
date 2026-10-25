import QtQuick
import QtTest
import "../../services/audio/AudioPresentationModel.js" as AudioPresentationModel

TestCase {
    name: "AudioPresentationModel"

    function change(overrides) {
        return Object.assign({
            sequence: 4,
            source: "local",
            role: "output",
            operation: "volume",
            changedFields: ["volume"],
            volume: 0.62,
            muted: false,
            deviceKey: "output:test",
            deviceName: "Test output"
        }, overrides || ({}));
    }

    function test_rejectsNonSemanticAndMalformedChanges() {
        compare(AudioPresentationModel.normalizedChange(change({
            changedFields: []
        }), "DP-1", 100, 1800), null);
        compare(AudioPresentationModel.normalizedChange(change({
            role: "playback-stream"
        }), "DP-1", 100, 1800), null);
        compare(AudioPresentationModel.normalizedChange(change({
            volume: Number.NaN
        }), "DP-1", 100, 1800), null);
    }

    function test_normalizesBoundedPresentation() {
        const result = AudioPresentationModel.normalizedChange(change(), "DP-1", 1200, 50000);

        verify(result !== null);
        compare(result.role, "output");
        compare(result.screenName, "DP-1");
        compare(result.durationMs, AudioPresentationModel.maximumDurationMs);
        compare(result.createdAtMs, 1200);
    }

    function test_outputFormattingTracksLevelAndMute() {
        compare(AudioPresentationModel.percent(change()), 62);
        compare(AudioPresentationModel.iconName(change()), "volumeHigh");
        compare(AudioPresentationModel.iconName(change({
            volume: 0.2
        })), "volumeLow");
        compare(AudioPresentationModel.iconName(change({
            muted: true
        })), "volumeMuted");
        compare(AudioPresentationModel.valueText(change({
            muted: true
        })), "Muted");
    }

    function test_inputUsesDedicatedMicrophoneState() {
        compare(AudioPresentationModel.iconName(change({
            role: "input"
        })), "microphone");
        compare(AudioPresentationModel.iconName(change({
            role: "input",
            muted: true
        })), "microphoneMuted");
    }
}
