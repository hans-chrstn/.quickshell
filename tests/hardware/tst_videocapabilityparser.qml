import QtQuick
import QtTest
import "../../services/hardware/VideoCapabilityParser.js" as Parser

TestCase {
    name: "VideoCapabilityParser"

    function test_decodeProfilesOnly() {
        const record = Parser.parseVainfo(`
            Driver version: Mesa Gallium driver 25.1
            VAProfileH264High : VAEntrypointVLD
            VAProfileH264High : VAEntrypointEncSlice
            VAProfileHEVCMain : VAEntrypointVLD
            VAProfileAV1Profile0 : VAEntrypointVLD
        `, "/dev/dri/renderD128")
        compare(record.driver, "Mesa Gallium driver 25.1")
        compare(JSON.stringify(record.decodeCodecs),
            JSON.stringify(["av1", "h264", "hevc"]))
        compare(Parser.recommendedCodec(record.decodeCodecs), "av1")
    }

    function test_conservativeFallback() {
        compare(Parser.recommendedCodec([]), "h264")
    }

    function test_encoderPolicyPreview() {
        const encoders = Parser.parseEncoders(`
 V....D libx264              H.264
 V....D libx265              HEVC
 V..... libsvtav1            AV1
        `)
        compare(JSON.stringify(encoders),
            JSON.stringify(["libsvtav1", "libx264", "libx265"]))
        const candidates = Parser.codecCandidates(
            ["av1", "h264", "hevc"], encoders)
        compare(candidates[0].policy, "conservative")
        compare(candidates[1].policy, "measurement-required")
        compare(candidates[2].encoder, "libsvtav1")
        verify(candidates[2].benchmarkable)
    }

    function test_unverifiedDecodeRemainsBenchmarkable() {
        const candidates = Parser.codecCandidates([], [
            "libx264", "libx265", "libsvtav1"
        ])
        compare(candidates[1].policy, "runtime-proof-required")
        verify(candidates[1].benchmarkable)
        verify(!candidates[1].eligible)
    }
}
