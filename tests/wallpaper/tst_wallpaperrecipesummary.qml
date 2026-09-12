import QtQuick
import QtTest
import "../../services/wallpaper/WallpaperRecipeSummary.js" as Summary

TestCase {
    name: "WallpaperRecipeSummary"

    function test_actualRecipeValues() {
        compare(Summary.describe({
            targetAvailable: true,
            outputWidth: 2560,
            outputHeight: 1440,
            codec: "h264",
            frameRate: 24,
            bitRateMbps: 8,
            audioRemoved: true
        }), "Original retained · 2560×1440 · H.264 · 24 FPS · ≤8 Mbps · Audio removed")
    }

    function test_futureCodecIsNotHardcoded() {
        compare(Summary.describe({
            targetAvailable: true,
            outputWidth: 1920,
            outputHeight: 1080,
            codec: "av1",
            frameRate: 15,
            bitRateMbps: 4.5
        }), "Original retained · 1920×1080 · AV1 · 15 FPS · ≤4.5 Mbps · Audio removed")
    }

    function test_unavailableTargetExplainsFailure() {
        compare(Summary.describe({
            targetAvailable: false,
            targetError: "The selected display is not connected"
        }), "The selected display is not connected")
    }
}
