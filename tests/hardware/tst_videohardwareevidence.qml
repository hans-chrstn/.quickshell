import QtQuick
import QtTest
import "../../services/hardware/VideoHardwareEvidence.js" as Evidence

TestCase {
    name: "VideoHardwareEvidence"

    function test_verifiedVaapi() {
        const result = Evidence.parseQtFfmpegLog(`
 DEBUG qt.multimedia.ffmpeg.hwaccel: Found potential codec "h264" for hw accel 3 ; Checking the hw device...
 DEBUG qt.multimedia.ffmpeg.hwaccel:     Checking HW context: vaapi
 DEBUG qt.multimedia.ffmpeg.hwaccel:     Using above hw context.
 DEBUG qt.multimedia.ffmpeg.hwaccel: HW device is OK
 DEBUG qt.multimedia.ffmpeg.hwaccel: Selected format 44 for hw 3
        `, "h264")
        verify(result.hardwareDecodeVerified)
        compare(result.backend, "vaapi")
    }

    function test_capabilityAloneIsInsufficient() {
        const result = Evidence.parseQtFfmpegLog(`
 DEBUG qt.multimedia.ffmpeg.hwaccel: Checking HW context: vaapi
 DEBUG qt.multimedia.ffmpeg.hwaccel: Using above hw context.
        `, "h264")
        verify(!result.hardwareDecodeVerified)
    }

    function test_wrongCodecIsRejected() {
        const result = Evidence.parseQtFfmpegLog(`
Found potential codec "hevc" for hw accel 3
Checking HW context: vaapi
HW device is OK
Selected format 44 for hw 3
        `, "h264")
        verify(!result.hardwareDecodeVerified)
    }
}
