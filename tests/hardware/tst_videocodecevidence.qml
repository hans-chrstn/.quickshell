import QtQuick
import QtTest
import "../../services/hardware/VideoCodecEvidence.js" as Evidence

TestCase {
    name: "VideoCodecEvidence"

    readonly property var eligibleCandidate: ({
        codec: "av1",
        encoder: "libsvtav1",
        benchmarkable: true,
        eligible: true
    })

    function test_emptyEvidenceCannotSelect() {
        const result = Evidence.evaluateCandidate(eligibleCandidate, ({}))
        compare(result.measurementState, "incomplete")
        verify(!result.measurementAccepted)
        verify(result.missingEvidence.length > 0)
        verify(!Evidence.automaticSelectionReady([result]))
    }

    function test_encodeOnlyIsInsufficient() {
        const result = Evidence.evaluateCandidate(eligibleCandidate, {
            av1: {
                runs: 3,
                playbackMs: 15000,
                encodeSucceeded: true
            }
        })
        verify(!result.measurementAccepted)
        verify(result.missingEvidence.indexOf(
            "successful Qt Multimedia playback") >= 0)
        verify(result.missingEvidence.indexOf(
            "verified hardware decode") >= 0)
    }

    function test_explicitNullDroppedFramesRemainMissing() {
        const result = Evidence.evaluateCandidate(eligibleCandidate, {
            av1: {
                runs: 3,
                playbackMs: 15000,
                encodeSucceeded: true,
                qtPlaybackSucceeded: true,
                hardwareDecodeVerified: true,
                hardwareTexturesVerified: true,
                droppedFrameRatio: null
            }
        })
        verify(!result.measurementAccepted)
        verify(result.missingEvidence.indexOf(
            "observed dropped-frame ratio") >= 0)
    }

    function test_completeEvidenceCanSelect() {
        const result = Evidence.evaluateCandidate(eligibleCandidate, {
            av1: {
                runs: 3,
                playbackMs: 18000,
                encodeSucceeded: true,
                qtPlaybackSucceeded: true,
                hardwareDecodeVerified: true,
                hardwareTexturesVerified: true,
                droppedFrameRatio: 0.005
            }
        })
        compare(result.measurementState, "accepted")
        verify(result.measurementAccepted)
        verify(Evidence.automaticSelectionReady([result]))
    }

    function test_unavailableCandidateCannotSelect() {
        const result = Evidence.evaluateCandidate({
            codec: "hevc",
            benchmarkable: false,
            eligible: false
        }, {
            hevc: {
                runs: 9,
                playbackMs: 90000,
                encodeSucceeded: true,
                qtPlaybackSucceeded: true,
                hardwareDecodeVerified: true,
                hardwareTexturesVerified: true,
                droppedFrameRatio: 0
            }
        })
        compare(result.measurementState, "unavailable")
        verify(!result.measurementAccepted)
    }

    function test_runtimeProofCanAcceptWithoutVainfoPreview() {
        const result = Evidence.evaluateCandidate({
            codec: "hevc",
            encoder: "libx265",
            benchmarkable: true,
            eligible: false
        }, {
            hevc: {
                runs: 3,
                playbackMs: 15000,
                encodeSucceeded: true,
                qtPlaybackSucceeded: true,
                hardwareDecodeVerified: true,
                hardwareTexturesVerified: true,
                droppedFrameRatio: 0
            }
        })
        verify(result.measurementAccepted)
    }

    function test_droppedFrameBoundary() {
        const accepted = Evidence.evaluateCandidate(eligibleCandidate, {
            av1: {
                runs: 3, playbackMs: 15000,
                encodeSucceeded: true, qtPlaybackSucceeded: true,
                hardwareDecodeVerified: true,
                hardwareTexturesVerified: true,
                droppedFrameRatio: 0.01
            }
        })
        verify(accepted.measurementAccepted)

        const rejected = Evidence.evaluateCandidate(eligibleCandidate, {
            av1: {
                runs: 3, playbackMs: 15000,
                encodeSucceeded: true, qtPlaybackSucceeded: true,
                hardwareDecodeVerified: true,
                hardwareTexturesVerified: true,
                droppedFrameRatio: 0.0101
            }
        })
        verify(!rejected.measurementAccepted)
    }
}
