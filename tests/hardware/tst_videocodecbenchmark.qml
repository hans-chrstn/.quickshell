import QtQuick
import QtTest
import "../../services/hardware/VideoCodecBenchmark.js" as Benchmark

TestCase {
    name: "VideoCodecBenchmark"

    function test_candidateFiltering() {
        const candidates = Benchmark.runnableCandidates([
            { codec: "h264", encoder: "libx264", eligible: true },
            { codec: "hevc", encoder: "libx265", eligible: false },
            { codec: "vp9", encoder: "libvpx-vp9", eligible: true }
        ])
        compare(candidates.length, 1)
        compare(candidates[0].codec, "h264")
    }

    function test_boundedH264Command() {
        const command = Benchmark.command("/bin/ffmpeg", "/tmp/in.mp4",
            "/tmp/out.mp4", {
                codec: "h264", encoder: "libx264", eligible: true
            })
        verify(command.indexOf("-t") >= 0)
        compare(command[command.indexOf("-t") + 1], "3")
        verify(command.indexOf("-an") >= 0)
        verify(command.indexOf("libx264") >= 0)
        verify(command.join(" ").indexOf("1280") >= 0)
    }

    function test_unknownEncoderHasNoCommand() {
        compare(Benchmark.command("ffmpeg", "in", "out", {
            codec: "av1", encoder: "unknown", eligible: true
        }).length, 0)
    }
}
