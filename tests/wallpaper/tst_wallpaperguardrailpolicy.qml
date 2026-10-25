import QtQuick
import QtTest
import "../../services/wallpaper/WallpaperGuardrailPolicy.js" as Policy

TestCase {
    name: "WallpaperGuardrailPolicy"

    function media(values) {
        return Object.assign({
            state: "ready", kind: "video", width: 1920, height: 1080,
            frameRate: 30, bitRate: 8000000, codec: "h264"
        }, values || ({}))
    }

    function test_ordinaryH264RemainsRecommended() {
        const result = Policy.assess(media(), ({}))
        compare(result.severity, 0)
        compare(result.issues.length, 0)
    }

    function test_unverifiedAdvancedCodecIsDeviceAware() {
        const result = Policy.assess(media({ codec: "av1" }), ({}))
        compare(result.severity, 1)
        verify(result.issues[0].indexOf("unverified on this device") >= 0)
    }

    function test_acceptedAdvancedPipelineAvoidsGenericWarning() {
        const result = Policy.assess(media({ codec: "av1" }), {
            decodeProfileVerified: true,
            pipelineAccepted: true
        })
        compare(result.severity, 0)
        compare(result.hardwareState, "accepted")
    }

    function test_hardwareDoesNotHideIntrinsic4k60Demand() {
        const result = Policy.assess(media({
            width: 3840, height: 2160, frameRate: 60, codec: "av1"
        }), { decodeProfileVerified: true, pipelineAccepted: true })
        compare(result.severity, 2)
        verify(result.issues.length >= 2)
    }

    function test_profileOnlyIsTruthfullyQualified() {
        const result = Policy.assess(media({ codec: "hevc" }), {
            decodeProfileVerified: true,
            pipelineAccepted: false
        })
        compare(result.severity, 0)
        compare(result.hardwareState, "decode-profile")
        verify(result.issues[0].indexOf("not yet verified") >= 0)
    }
}
