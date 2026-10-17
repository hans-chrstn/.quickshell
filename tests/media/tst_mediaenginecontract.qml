import QtTest
import "../../services/media/MediaEngineContract.js" as Media

TestCase {
    name: "MediaEngineContract"

    function test_capabilitiesAreNormalized() {
        const result = Media.capabilities({
            available: true, metadata: true, keyframeIndex: true,
            frameExtraction: true, hardwareDecode: false,
            reason: "ready"
        })
        verify(result.available)
        verify(result.metadata)
        verify(result.keyframeIndex)
        verify(result.frameExtraction)
        verify(!result.hardwareDecode)
        compare(result.reason, "ready")
    }

    function test_frameRequestIsBounded() {
        const result = Media.frameRequest(2, " /tmp/video.mp4 ", -9)
        compare(result.generation, 2)
        compare(result.path, "/tmp/video.mp4")
        compare(result.timestampMs, 0)
        verify(result.valid)
    }

    function test_staleFrameCannotCompleteRequest() {
        const request = Media.frameRequest(4, "/tmp/video.mp4", 1200)
        verify(Media.requestIsCurrent(request, {
            generation: 4, path: "/tmp/video.mp4", timestampMs: 1200
        }))
        verify(!Media.requestIsCurrent(request, {
            generation: 3, path: "/tmp/video.mp4", timestampMs: 1200
        }))
        verify(!Media.requestIsCurrent(request, {
            generation: 4, path: "/tmp/other.mp4", timestampMs: 1200
        }))
    }

    function test_metadataRequestRejectsEmptyPath() {
        verify(!Media.metadataRequest(1, "").valid)
    }
}
