import QtQuick
import QtTest
import "../../services/hardware/VideoCodecSelection.js" as Selection

TestCase {
    name: "VideoCodecSelection"

    readonly property var candidates: [
        { codec: "h264", encoder: "libx264" },
        { codec: "hevc", encoder: "libx265" },
        { codec: "av1", encoder: "libsvtav1" }
    ]

    function test_incompleteEvidenceUsesConservativeFallback() {
        const result = Selection.select([
            { codec: "av1", encoder: "libsvtav1",
                measurementAccepted: false }
        ], candidates)
        compare(result.codec, "h264")
        compare(result.encoder, "libx264")
        compare(result.selectionReason, "conservative-fallback")
    }

    function test_acceptedEvidenceSelectsMeasuredCandidate() {
        const result = Selection.select([
            { codec: "av1", encoder: "libsvtav1",
                measurementAccepted: true,
                evidence: { droppedFrameRatio: 0, encodeElapsedMs: 400 } }
        ], candidates)
        compare(result.codec, "av1")
        compare(result.selectionReason, "accepted-runtime-evidence")
    }

    function test_measurementsChooseLowerObservedCost() {
        const result = Selection.select([
            { codec: "hevc", encoder: "libx265",
                measurementAccepted: true,
                evidence: { droppedFrameRatio: 0.01, encodeElapsedMs: 100 } },
            { codec: "av1", encoder: "libsvtav1",
                measurementAccepted: true,
                evidence: { droppedFrameRatio: 0, encodeElapsedMs: 800 } },
            { codec: "h264", encoder: "libx264",
                measurementAccepted: true,
                evidence: { droppedFrameRatio: 0, encodeElapsedMs: 200 } }
        ], candidates)
        compare(result.codec, "h264")
    }
}
