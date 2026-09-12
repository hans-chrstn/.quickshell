import QtQuick
import QtTest
import "../../services/wallpaper/WallpaperRenderSupport.js" as Support

TestCase {
    name: "WallpaperAnimatedSupport"

    function test_confirmedBackends() {
        compare(Support.animatedBackendFor({ kind: "animatedImage", codec: "gif" }),
            "image")
        compare(Support.animatedBackendFor({ kind: "animatedImage", codec: "GIF" }),
            "image")
        compare(Support.animatedBackendFor({ kind: "animatedImage", codec: "apng" }),
            "media")
    }

    function test_unconfirmedAnimatedWebpIsRejected() {
        compare(Support.animatedBackendFor({
            kind: "animatedImage", codec: "webp_anim"
        }), "")
        verify(!Support.supported({
            kind: "animatedImage", codec: "webp_anim"
        }))
    }

    function test_nonAnimatedMediaIsRejected() {
        compare(Support.animatedBackendFor({ kind: "static", codec: "gif" }), "")
        compare(Support.animatedBackendFor({ kind: "video", codec: "apng" }), "")
        compare(Support.animatedBackendFor(null), "")
    }

    function test_generalRendererSupport() {
        compare(Support.rendererFor({ kind: "static", codec: "png" }),
            "static")
        compare(Support.rendererFor({ kind: "video", codec: "h264" }),
            "video")
        compare(Support.rendererFor({ kind: "static", codec: "webp" }), "")
        verify(!Support.supported({ kind: "static", codec: "webp" }))
    }
}
