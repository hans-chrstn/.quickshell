import QtQuick
import QtTest
import "../../services/hardware/VideoPlaybackMetrics.js" as Metrics

TestCase {
    name: "VideoPlaybackMetrics"

    function test_exactRun() {
        const result = Metrics.run(24, 5000, 120, 5002)
        verify(result.valid)
        compare(result.expectedFrames, 120)
        compare(result.droppedFrameRatio, 0)
    }

    function test_droppedFrames() {
        const result = Metrics.run(24, 5000, 117, 5000)
        verify(result.valid)
        compare(result.droppedFrames, 3)
        compare(result.droppedFrameRatio, 0.025)
    }

    function test_suspendInvalidatesRun() {
        const result = Metrics.run(24, 5000, 20, 600000)
        verify(!result.valid)
        verify(result.error.length > 0)
    }

    function test_aggregate() {
        const result = Metrics.aggregate([
            Metrics.run(24, 5000, 120, 5000),
            Metrics.run(24, 5000, 119, 5000),
            Metrics.run(24, 5000, 118, 5000)
        ])
        compare(result.validRuns, 3)
        compare(result.expectedFrames, 360)
        compare(result.droppedFrames, 3)
    }
}
