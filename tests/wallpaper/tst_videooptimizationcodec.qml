import QtQuick
import QtTest
import "../../services/wallpaper/VideoOptimizationCodec.js" as Codec

TestCase {
    name: "VideoOptimizationCodec"

    function test_missingCandidateFallsBackToH264() {
        const result = Codec.recipe(null)
        compare(result.codec, "h264")
        compare(result.encoder, "libx264")
        verify(result.arguments.indexOf("libx264") >= 0)
    }

    function test_measuredHevcHasIndependentRecipeIdentity() {
        const result = Codec.recipe({ codec: "hevc", encoder: "libx265" })
        compare(result.codec, "hevc")
        compare(result.encoder, "libx265")
        verify(result.version.indexOf("hevc") === 0)
        verify(result.arguments.indexOf("hvc1") >= 0)
    }

    function test_supportedAv1EncodersHaveDistinctRecipes() {
        const svt = Codec.recipe({ codec: "av1", encoder: "libsvtav1" })
        const aom = Codec.recipe({ codec: "av1", encoder: "libaom-av1" })
        compare(svt.codec, "av1")
        compare(aom.codec, "av1")
        verify(svt.version !== aom.version)
    }

    function test_unknownMeasuredEncoderCannotEscapeFallback() {
        const result = Codec.recipe({ codec: "av1", encoder: "unknown" })
        compare(result.codec, "h264")
        compare(result.encoder, "libx264")
    }
}
